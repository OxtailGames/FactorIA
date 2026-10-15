// /ci: the CI checks of the current branch's GitHub pull request (or `/ci <number>`, `/ci owner/repo#<number>`).
// Data comes from the GitHub REST API through `gh api` (the host's gh login or proxy). While checks are still
// running, the mod re-checks every minute, keeps a status-line summary and raises a toast when they finish;
// `/ci off` stops that. `/ci prs` lists every open pull request and whether it can be merged now.
import type { EngineInterface, Register } from 'claude-code'

import { type CheckRun, type PullRequest, type Target, counts, parse_args, parse_remote, prs_report, report, status_line, verdict } from './ci'

const POLL_MS = 60_000

type Fetched = { pr: PullRequest; checks: CheckRun[] } | { error: string }

async function gh<T>($: EngineInterface, path: string): Promise<T> {
  const r = await $.process.run(['gh', 'api', '-H', 'Accept: application/vnd.github+json', path], { timeoutMs: 30_000 })
  if (r.exitCode !== 0) {
    const why = (r.stderr || r.stdout).trim().split('\n')[0] || `exit code ${r.exitCode}`
    throw new Error(`gh api ${path}: ${why}`)
  }
  return JSON.parse(r.stdout) as T
}

async function git($: EngineInterface, ...args: string[]): Promise<string | undefined> {
  try {
    const r = await $.process.run(['git', ...args])
    return r.exitCode === 0 ? r.stdout.trim() : undefined
  } catch {
    return undefined
  }
}

async function resolve($: EngineInterface, args: string): Promise<Target | { error: string }> {
  const url = await git($, 'remote', 'get-url', 'origin')
  const t = parse_args(args, url ? parse_remote(url) : undefined)
  if ('error' in t || t.number !== undefined) return t
  const branch = await git($, 'rev-parse', '--abbrev-ref', 'HEAD')
  if (!branch || branch === 'HEAD') return { error: 'not on a branch: run /ci <number>' }
  const prs = await gh<PullRequest[]>($, `repos/${t.owner}/${t.repo}/pulls?head=${t.owner}:${encodeURIComponent(branch)}&state=all&per_page=5`)
  const pr = prs[0]
  if (!pr) return { error: `no pull request for branch ${branch} in ${t.owner}/${t.repo}: run /ci <number>` }
  return { ...t, number: pr.number }
}

async function fetch_ci($: EngineInterface, t: Target): Promise<Fetched> {
  try {
    const pr = await gh<PullRequest>($, `repos/${t.owner}/${t.repo}/pulls/${t.number}`)
    const runs = await gh<{ check_runs: CheckRun[] }>($, `repos/${t.owner}/${t.repo}/commits/${pr.head.sha}/check-runs?per_page=100`)
    return { pr, checks: runs.check_runs }
  } catch (err) {
    return { error: err instanceof Error ? err.message : String(err) }
  }
}

// Every open PR with its detail (the list endpoint lacks mergeable_state) and its head's checks.
async function open_prs($: EngineInterface): Promise<string> {
  const url = await git($, 'remote', 'get-url', 'origin')
  const t = parse_args('', url ? parse_remote(url) : undefined)
  if ('error' in t) return `/ci: ${t.error}`
  const repo = `${t.owner}/${t.repo}`
  try {
    const list = await gh<PullRequest[]>($, `repos/${repo}/pulls?state=open&per_page=30`)
    const prs = await Promise.all(list.map(async p => {
      const got = await fetch_ci($, { ...t, number: p.number })
      if ('error' in got) throw new Error(got.error)
      return got
    }))
    return prs_report(repo, prs)
  } catch (err) {
    return `/ci: ${err instanceof Error ? err.message : String(err)}`
  }
}

// The pull request being watched (module state: a reload starts over, and the next /ci re-arms it).
let watch: { key: string; cancel: () => void } | undefined

function stop($: EngineInterface): void {
  watch?.cancel()
  watch = undefined
  $.ui.status(undefined)
}

// Re-checks every minute while checks run; says once when they are all done.
function start_watch($: EngineInterface, t: Target): void {
  const key = `${t.owner}/${t.repo}#${t.number}`
  if (watch?.key === key) return
  watch?.cancel()
  let busy = false
  const timer = $.clock.every(POLL_MS, () => {
    if (busy) return
    busy = true
    void poll($, t, key).finally(() => { busy = false })
  })
  watch = { key, cancel: () => timer.cancel() }
}

async function poll($: EngineInterface, t: Target, key: string): Promise<void> {
  const got = await fetch_ci($, t)
  if ('error' in got) return  // keep watching: the next minute may answer
  $.ui.status(status_line(got.pr, got.checks))
  if (counts(got.checks).running === 0 && got.checks.length > 0) {
    $.ui.toast(`CI ${key} finished: ${verdict(got.checks)}`, { timeoutMs: 15_000 })
    watch?.cancel()
    watch = undefined
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'ci',
      description: "Show the CI checks of this branch's GitHub pull request",
      argumentHint: '[number | owner/repo#number | prs | off]',
      immediate: true,
    })
    return next(e)
  })

  on('command.run', { command: 'ci' }, async ($, e) => {
    const args = (e.args ?? '').trim()
    if (args === 'off') {
      const was = watch?.key
      stop($)
      return { text: was ? `Stopped watching CI of ${was}.` : 'Not watching any pull request.' }
    }
    if (args === 'prs') return { text: await open_prs($) }
    let t: Target | { error: string }
    try {
      t = await resolve($, args)
    } catch (err) {
      t = { error: err instanceof Error ? err.message : String(err) }
    }
    if ('error' in t) return { text: `/ci: ${t.error}` }
    const got = await fetch_ci($, t)
    if ('error' in got) return { text: `/ci: ${got.error}` }
    $.ui.status(status_line(got.pr, got.checks))
    const running = counts(got.checks).running > 0
    if (running && got.pr.state === 'open') start_watch($, t)
    const tail = running && got.pr.state === 'open' ? '\n\nWatching: the status line updates every minute until the checks finish (/ci off stops).' : ''
    return { text: report(got.pr, got.checks, t, await $.clock.now()) + tail }
  })
}
