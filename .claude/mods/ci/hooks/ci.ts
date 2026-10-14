// Pure logic of the /ci mod: which PR to show, and how to print its checks. No `$` here, so tests reach it directly.

export type Target = { owner: string; repo: string; number?: number }

export type PullRequest = {
  number: number
  title: string
  state: string
  merged: boolean
  draft: boolean
  mergeable_state: string
  html_url: string
  head: { sha: string; ref: string }
}

export type CheckRun = {
  name: string
  status: string
  conclusion: string | null
  started_at: string | null
  completed_at: string | null
  html_url: string | null
}

export type Kind = 'failed' | 'running' | 'passed' | 'skipped'

const FAILED = new Set(['failure', 'timed_out', 'cancelled', 'action_required', 'startup_failure', 'stale'])
const SKIPPED = new Set(['skipped', 'neutral'])
const ICON: Record<Kind, string> = { failed: '❌', running: '⏳', passed: '✅', skipped: '⚪' }
const ORDER: Record<Kind, number> = { failed: 0, running: 1, passed: 2, skipped: 3 }

// owner/repo from a git remote URL: https://github.com/o/r(.git), git@github.com:o/r.git, or a proxy URL ending in /o/r.
export function parse_remote(url: string): { owner: string; repo: string } | undefined {
  const m = url.trim().match(/[/:]([^/:]+)\/([^/]+?)(?:\.git)?\/?$/)
  return m && m[1] && m[2] ? { owner: m[1], repo: m[2] } : undefined
}

// `/ci` arguments: "" (PR of the current branch), "2" or "#2", "owner/repo#2", "owner/repo" (that repo, current branch).
export function parse_args(args: string, remote?: { owner: string; repo: string }): Target | { error: string } {
  const a = args.trim()
  const full = a.match(/^([\w.-]+)\/([\w.-]+)(?:#(\d+))?$/)
  if (full && full[1] && full[2]) return { owner: full[1], repo: full[2], number: full[3] ? Number(full[3]) : undefined }
  if (!remote) return { error: 'no GitHub remote named origin here: run /ci owner/repo#<number>' }
  if (a === '') return { ...remote }
  const num = a.match(/^#?(\d+)$/)
  if (num && num[1]) return { ...remote, number: Number(num[1]) }
  return { error: `cannot read "${a}": use /ci, /ci <number>, /ci owner/repo#<number> or /ci off` }
}

export function kind_of(c: CheckRun): Kind {
  if (c.status !== 'completed') return 'running'
  if (c.conclusion && FAILED.has(c.conclusion)) return 'failed'
  if (c.conclusion && SKIPPED.has(c.conclusion)) return 'skipped'
  return 'passed'
}

export function duration(ms: number): string {
  if (!(ms >= 0)) return ''
  const s = Math.round(ms / 1000)
  const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60), r = s % 60
  return h > 0 ? `${h}h ${m}m` : m > 0 ? `${m}m ${r}s` : `${r}s`
}

export function counts(checks: readonly CheckRun[]): Record<Kind, number> {
  const out: Record<Kind, number> = { failed: 0, running: 0, passed: 0, skipped: 0 }
  for (const c of checks) out[kind_of(c)] += 1
  return out
}

// One short line for the status bar: "CI #2 ✅5 ⏳1".
export function status_line(pr: PullRequest, checks: readonly CheckRun[]): string {
  const n = counts(checks)
  const parts = (['failed', 'running', 'passed'] as const).filter(k => n[k] > 0).map(k => `${ICON[k]}${n[k]}`)
  return `CI #${pr.number} ${parts.length ? parts.join(' ') : 'no checks'}`
}

// The verdict: what a person wants first.
export function verdict(checks: readonly CheckRun[]): string {
  const n = counts(checks)
  if (checks.length === 0) return 'No checks reported for the head commit yet.'
  if (n.failed > 0) return `${ICON.failed} ${n.failed} failed, ${n.running} running, ${n.passed} passed`
  if (n.running > 0) return `${ICON.running} ${n.running} running, ${n.passed} passed`
  return `${ICON.passed} all ${n.passed} passed` + (n.skipped ? ` (${n.skipped} skipped)` : '')
}

export function report(pr: PullRequest, checks: readonly CheckRun[], target: Target, nowMs: number): string {
  const state = pr.merged ? 'merged' : pr.draft && pr.state === 'open' ? 'draft' : pr.state
  const merge = pr.state === 'open' && pr.mergeable_state && pr.mergeable_state !== 'unknown'
    ? ` · merge state: ${pr.mergeable_state}${pr.mergeable_state === 'dirty' ? ' (conflict with the base branch)' : ''}`
    : ''
  const lines = [
    `CI of ${target.owner}/${target.repo}#${pr.number}: ${pr.title}`,
    `${pr.html_url}`,
    `head ${pr.head.sha.slice(0, 7)} (${pr.head.ref}) · ${state}${merge}`,
    verdict(checks),
    '',
  ]
  const sorted = [...checks].sort((a, b) => ORDER[kind_of(a)] - ORDER[kind_of(b)] || a.name.localeCompare(b.name))
  for (const c of sorted) {
    const k = kind_of(c)
    const start = c.started_at ? Date.parse(c.started_at) : NaN
    const end = c.completed_at ? Date.parse(c.completed_at) : nowMs
    const took = duration(end - start)
    const what = k === 'running' ? c.status.replace('_', ' ') : (c.conclusion ?? 'done').replace('_', ' ')
    lines.push(`${ICON[k]} ${c.name}: ${what}${took ? `, ${took}` : ''}`)
    if (c.html_url && k !== 'passed' && k !== 'skipped') lines.push(`   ${c.html_url}`)
  }
  return lines.join('\n')
}
