// Turns an "Add a project" issue (.github/ISSUE_TEMPLATE/add-project.yml) into
// a pull request that adds the project to data/projects.yml.
//
// Used by .github/workflows/project-request.yml through actions/github-script.
// The issue body is untrusted input: it is only ever parsed as data, every
// value is written as a quoted-when-needed YAML scalar, and the result is
// validated by generate-readme before a pull request is opened.

const fs = require('fs')
const path = require('path')

const DATA_PATH = 'data/projects.yml'
const COMMENT_MARKER = '<!-- project-request -->'
const LABELS = {
  name: 'Project name',
  url: 'Repository URL',
  description: 'Description',
  category: 'Category',
  platforms: 'Platforms',
}

function problemsPath() {
  return path.join(process.env.RUNNER_TEMP || '.', 'project-request-problems.txt')
}

// Issue forms render each field as "### <label>" followed by its value.
function parseIssueForm(body) {
  const fields = {}
  const text = (body || '').replace(/\r\n/g, '\n')
  for (const section of text.split(/^### /m).slice(1)) {
    const newline = section.indexOf('\n')
    const label = (newline === -1 ? section : section.slice(0, newline)).trim()
    const value = newline === -1 ? '' : section.slice(newline + 1).trim()
    fields[label] = value === '_No response_' ? '' : value
  }
  return fields
}

function checkedOptions(value) {
  return (value || '')
    .split('\n')
    .map((line) => line.match(/^- \[[xX]\] (.+)$/))
    .filter(Boolean)
    .map((match) => match[1].trim())
}

function unquote(value) {
  const trimmed = value.trim()
  if (/^".*"$/.test(trimmed)) {
    return JSON.parse(trimmed)
  }
  if (/^'.*'$/.test(trimmed)) {
    return trimmed.slice(1, -1).replace(/''/g, "'")
  }
  return trimmed
}

// Maps category names (and ids) to ids from the categories list.
function categoryIDs(yaml) {
  const ids = new Map()
  for (const match of yaml.matchAll(/^\s*- id:\s*(.+)\n\s+name:\s*(.+)$/gm)) {
    const id = unquote(match[1])
    ids.set(unquote(match[2]).toLowerCase(), id)
    ids.set(id.toLowerCase(), id)
  }
  return ids
}

// Writes a string as a plain YAML scalar when that is unambiguous, and as a
// double-quoted scalar (JSON strings are valid YAML) otherwise.
function scalar(value) {
  const plainText = /^[A-Za-z0-9][A-Za-z0-9 .,;()'&/+!?_-]*$/
  const plainURL = /^https?:\/\/[A-Za-z0-9._~/?=&%+-]+$/
  const reserved = /^(true|false|yes|no|on|off|null|y|n)$/i
  const numeric = /^[-+]?[0-9][0-9_]*(\.[0-9]*)?([eE][-+]?[0-9]+)?$/
  const isPlain =
    (plainText.test(value) || plainURL.test(value)) &&
    !reserved.test(value) &&
    !numeric.test(value) &&
    !value.endsWith(' ')
  return isPlain ? value : JSON.stringify(value)
}

// Inserts the entry after the last project, before the next top-level key.
function insertProject(yaml, entryLines) {
  const lines = yaml.split('\n')
  const start = lines.findIndex((line) => /^projects:\s*$/.test(line))
  if (start === -1) {
    throw new Error(`${DATA_PATH} has no top-level "projects:" list.`)
  }
  let end = lines.findIndex((line, index) => index > start && /^[A-Za-z_][\w-]*:/.test(line))
  if (end === -1) {
    end = lines.length
  }
  let last = end - 1
  while (last > start && (lines[last].trim() === '' || lines[last].startsWith('#'))) {
    last -= 1
  }
  lines.splice(last + 1, 0, '', ...entryLines)
  return lines.join('\n')
}

function singleLine(label, value, problems, maxLength) {
  if (!value) {
    problems.push(`"${label}" is required.`)
  } else if (value.includes('\n')) {
    problems.push(`"${label}" must be a single line.`)
  } else if (value.length > maxLength) {
    problems.push(`"${label}" must be ${maxLength} characters or fewer.`)
  }
  return value
}

// Step 1: validate the issue form and add the project to data/projects.yml.
async function prepare({ core, context }) {
  const fields = parseIssueForm(context.payload.issue.body)
  const problems = []

  const name = singleLine(LABELS.name, fields[LABELS.name], problems, 80)
  const url = singleLine(LABELS.url, fields[LABELS.url], problems, 200)
  const description = singleLine(LABELS.description, fields[LABELS.description], problems, 200)
  const categoryName = fields[LABELS.category] || ''
  const platforms = checkedOptions(fields[LABELS.platforms])

  if (url && !url.includes('\n')) {
    try {
      const parsed = new URL(url)
      if (parsed.protocol !== 'https:' && parsed.protocol !== 'http:') {
        problems.push(`"${LABELS.url}" must be an http(s) URL.`)
      }
    } catch {
      problems.push(`"${LABELS.url}" is not a valid URL: ${url}`)
    }
  }

  const yaml = fs.readFileSync(DATA_PATH, 'utf8')
  const ids = categoryIDs(yaml)
  const category = ids.get(categoryName.toLowerCase())
  if (!category) {
    problems.push(`Unknown category "${categoryName}".`)
  }

  if (problems.length > 0) {
    fs.writeFileSync(problemsPath(), problems.map((problem) => `- ${problem}`).join('\n'))
    core.setFailed(`The issue form has ${problems.length} problem(s).`)
    return
  }

  const entryLines = [
    `  - name: ${scalar(name)}`,
    `    url: ${scalar(url)}`,
    `    description: ${scalar(description)}`,
    `    category: ${scalar(category)}`,
  ]
  if (platforms.length > 0) {
    entryLines.push(`    platforms: [${platforms.map(scalar).join(', ')}]`)
  }
  fs.writeFileSync(DATA_PATH, insertProject(yaml, entryLines))
  core.setOutput('name', name)
  core.setOutput('entry', entryLines.join('\n'))
}

// Creates or updates the single bot comment on the issue.
async function upsertComment({ github, context }, body) {
  const { owner, repo } = context.repo
  const issue_number = context.payload.issue.number
  const comments = await github.paginate(github.rest.issues.listComments, {
    owner,
    repo,
    issue_number,
  })
  const existing = comments.find(
    (comment) => comment.user.type === 'Bot' && comment.body.includes(COMMENT_MARKER)
  )
  const fullBody = `${COMMENT_MARKER}\n${body}`
  if (existing) {
    await github.rest.issues.updateComment({ owner, repo, comment_id: existing.id, body: fullBody })
  } else {
    await github.rest.issues.createComment({ owner, repo, issue_number, body: fullBody })
  }
}

// Step 3: commit the change to project-request/issue-N and open (or update) its PR.
async function openPullRequest({ github, context }) {
  const { owner, repo } = context.repo
  const issue = context.payload.issue
  const base = context.payload.repository.default_branch
  const branch = `project-request/issue-${issue.number}`
  const name = process.env.PROJECT_NAME
  const entry = process.env.PROJECT_ENTRY

  // Start the branch from the commit this run checked out, so an edited issue
  // replaces the previous attempt instead of stacking another entry on it.
  try {
    await github.rest.git.updateRef({ owner, repo, ref: `heads/${branch}`, sha: context.sha, force: true })
  } catch (error) {
    if (error.status !== 404 && error.status !== 422) {
      throw error
    }
    await github.rest.git.createRef({ owner, repo, ref: `refs/heads/${branch}`, sha: context.sha })
  }

  const { data: file } = await github.rest.repos.getContent({ owner, repo, path: DATA_PATH, ref: branch })
  await github.rest.repos.createOrUpdateFileContents({
    owner,
    repo,
    path: DATA_PATH,
    branch,
    sha: file.sha,
    message: `Add ${name}\n\nRequested in #${issue.number}.`,
    content: Buffer.from(fs.readFileSync(DATA_PATH, 'utf8')).toString('base64'),
  })

  const title = `Add ${name}`
  const fence = entry.includes('```') ? '````' : '```'
  const body = [
    `Adds **${name}** to \`${DATA_PATH}\`, as requested by @${issue.user.login} in #${issue.number}.`,
    '',
    `${fence}yaml`,
    entry,
    fence,
    '',
    'The entry was validated with `generate-readme`. `README.md` is regenerated automatically after this is merged.',
    '',
    `Closes #${issue.number}`,
  ].join('\n')

  const { data: open } = await github.rest.pulls.list({ owner, repo, head: `${owner}:${branch}`, state: 'open' })
  let pull = open[0]
  if (pull) {
    await github.rest.pulls.update({ owner, repo, pull_number: pull.number, title, body })
  } else {
    pull = (await github.rest.pulls.create({ owner, repo, title, head: branch, base, body })).data
  }

  await upsertComment(
    { github, context },
    `Thanks! Pull request #${pull.number} adds **${name}** and is waiting for a maintainer to review it. Editing this issue updates the pull request.`
  )
}

// Runs when an earlier step failed: explain what to fix on the issue.
async function reportProblems({ github, context }) {
  const details = fs.existsSync(problemsPath()) ? fs.readFileSync(problemsPath(), 'utf8').trim() : ''
  const run = `${context.serverUrl}/${context.repo.owner}/${context.repo.repo}/actions/runs/${context.runId}`
  const fence = details.includes('```') ? '````' : '```'
  const explanation = details
    ? `${fence}\n${details}\n${fence}`
    : `Something went wrong; see the [workflow run](${run}).`
  await upsertComment(
    { github, context },
    `I couldn't turn this into a pull request yet:\n\n${explanation}\n\nEdit the issue to fix it and I'll try again.`
  )
}

module.exports = {
  prepare,
  openPullRequest,
  reportProblems,
  // Exported for local testing.
  parseIssueForm,
  categoryIDs,
  insertProject,
  scalar,
}
