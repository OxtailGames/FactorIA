import type { On } from 'claude-code'
import { describe, expect, mock, test } from 'claude-code/testing'

import { parse_args, parse_remote, report } from '../hooks/ci'

const PR = {
  number: 2, title: 'Close the last gaps', state: 'open', merged: false, draft: false, mergeable_state: 'unstable',
  html_url: 'https://github.com/OxtailGames/FactorIA/pull/2', head: { sha: '0a82433a35ea441b', ref: 'claude/x' },
}
const T0 = Date.parse('2026-10-13T21:20:00Z')
const run = (name: string, status: string, conclusion: string | null, startedMin: number, endedMin?: number) => ({
  name, status, conclusion, html_url: `https://github.com/OxtailGames/FactorIA/actions/runs/1/job/${name.length}`,
  started_at: new Date(T0 + startedMin * 60_000).toISOString(),
  completed_at: endedMin === undefined ? null : new Date(T0 + endedMin * 60_000).toISOString(),
})
// What the engine stamps on a /ci typed at the prompt.
const ci = (args: string) => ({
  command: 'ci', args, origin: { kind: 'composer' as const }, presentation: { isFullscreen: false, columns: 120 },
})
const RUNNING = [run('Linux', 'completed', 'success', 0, 2), run('Windows', 'in_progress', null, 0)]
const DONE = [run('Linux', 'completed', 'success', 0, 2), run('Windows', 'completed', 'failure', 0, 15)]

// Answers the plugin's git and gh calls; `runs()` is read on every call so a test can change the CI state.
function host(on: On, runs: () => unknown[], calls: string[]): void {
  on('process.run', async (_$, e) => {
    const cmd = e.argv.join(' ')
    calls.push(cmd)
    const ok = (stdout: string) => ({ value: { exitCode: 0, stdout, stderr: '', isStdoutTruncated: false, isStderrTruncated: false } })
    if (cmd === 'git remote get-url origin') return ok('https://github.com/OxtailGames/FactorIA\n')
    if (cmd === 'git rev-parse --abbrev-ref HEAD') return ok('claude/x\n')
    if (cmd.includes('/pulls?head=OxtailGames:claude%2Fx')) return ok(JSON.stringify([PR]))
    if (cmd.endsWith('repos/OxtailGames/FactorIA/pulls/2')) return ok(JSON.stringify(PR))
    if (cmd.includes('/commits/0a82433a35ea441b/check-runs')) return ok(JSON.stringify({ check_runs: runs() }))
    return { value: { exitCode: 1, stdout: '', stderr: `HTTP 404: Not Found (${cmd})`, isStdoutTruncated: false, isStderrTruncated: false } }
  })
}

describe('parsing', () => {
  test('remotes and arguments', async () => {
    expect(parse_remote('https://github.com/OxtailGames/FactorIA')).toEqual({ owner: 'OxtailGames', repo: 'FactorIA' })
    expect(parse_remote('git@github.com:o/r.git')).toEqual({ owner: 'o', repo: 'r' })
    expect(parse_remote('http://proxy@127.0.0.1:8080/git/o/r')).toEqual({ owner: 'o', repo: 'r' })
    const remote = { owner: 'o', repo: 'r' }
    expect(parse_args('', remote)).toEqual({ owner: 'o', repo: 'r' })
    expect(parse_args('#7', remote)).toEqual({ owner: 'o', repo: 'r', number: 7 })
    expect(parse_args('a/b#3', undefined)).toEqual({ owner: 'a', repo: 'b', number: 3 })
    expect('error' in parse_args('banana', remote)).toBe(true)
  })

  test('report puts failures first and links what is not green', async () => {
    const text = report(PR, DONE, { owner: 'OxtailGames', repo: 'FactorIA', number: 2 }, T0)
    const lines = text.split('\n')
    expect(text).toContain('❌ 1 failed, 0 running, 1 passed')
    expect(lines.findIndex(l => l.startsWith('❌ Windows: failure, 15m 0s'))).toBeLessThan(lines.findIndex(l => l.startsWith('✅ Linux')))
    expect(text).toContain('https://github.com/OxtailGames/FactorIA/actions/runs/1/job/7')
    expect(text).not.toContain('job/5')  // passed checks are not linked
  })
})

test('/ci finds the branch PR, prints its checks and watches until they finish', async ($, on) => {
  let runs: unknown[] = RUNNING
  const calls: string[] = []
  const statuses: (string | undefined)[] = []
  const toasts: string[] = []
  host(on, () => runs, calls)
  on('ui.status', async (_$, e) => { statuses.push(e.text); return { value: undefined } })
  on('ui.toast', async (_$, e) => { toasts.push(e.text); return { value: undefined } })
  const clock = mock.clock(on, { now: T0 + 5 * 60_000 })

  const out = await $.command.run(ci(''))
  expect(out.text).toContain('CI of OxtailGames/FactorIA#2: Close the last gaps')
  expect(out.text).toContain('⏳ 1 running, 1 passed')
  expect(out.text).toContain('⏳ Windows: in progress, 5m 0s')
  expect(out.text).toContain('Watching')
  expect(statuses.at(-1)).toBe('CI #2 ⏳1 ✅1')

  await clock.advance(60_000)  // still running: the status line updates, no toast
  expect(toasts).toEqual([])
  runs = DONE
  await clock.advance(60_000)
  expect(statuses.at(-1)).toBe('CI #2 ❌1 ✅1')
  expect(toasts).toEqual(['CI OxtailGames/FactorIA#2 finished: ❌ 1 failed, 0 running, 1 passed'])
  const polls = calls.filter(c => c.includes('check-runs')).length
  await clock.advance(5 * 60_000)  // finished: no more polling
  expect(calls.filter(c => c.includes('check-runs')).length).toBe(polls)
})

test('/ci off, explicit numbers and errors', async ($, on) => {
  const calls: string[] = []
  host(on, () => DONE, calls)
  on('ui.status', async () => ({ value: undefined }))
  mock.clock(on, { now: T0 })

  expect((await $.command.run(ci('off'))).text).toBe('Not watching any pull request.')
  const out = await $.command.run(ci('2'))
  expect(out.text).toContain('❌ Windows: failure')
  expect(out.text).not.toContain('Watching')
  expect(calls.some(c => c.includes('pulls?head='))).toBe(false)  // a number skips the branch lookup
  const missing = await $.command.run(ci('99'))
  expect(missing.text).toContain('/ci: gh api repos/OxtailGames/FactorIA/pulls/99: HTTP 404')
  expect((await $.command.run(ci('banana'))).text).toContain('/ci: cannot read "banana"')
})
