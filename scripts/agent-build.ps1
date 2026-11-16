#requires -Version 5.1
<#
.SYNOPSIS
    Build (and test) a Ninja + MSVC Debug tree from any shell, printing only what matters. See docs/design/BUILDING.md.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts\agent-build.ps1 build\agent-<name> [-Target fa_test_core[,fa_test_scene]] [-Test] [-Tests <ctest -R regex>] [-Examples] [-Jobs 8]

    At most FA_AGENT_MAX_JOBS (default 3) jobs build or test at once on the machine: one more waits for a build slot.
    The full check before a push: -Test -Examples (the Debug suite, then a Release build of factoria in <BuildDir>-release
    running `ctest -L example`, the example games' tests, which are disabled in a Debug build). -ExamplesOnly skips the Debug part.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$BuildDir,

    # Comma-separated targets; default: all.
    [string]$Target,

    # Run every test after the build.
    [switch]$Test,

    # Run only the tests matching this regex (ctest -R); implies -Test.
    [string]$Tests,

    # After the Debug part: build factoria in Release (<BuildDir>-release) and run the example games' tests (ctest -L example).
    [switch]$Examples,

    # Only the Release example run (implies -Examples; no Debug build or tests).
    [switch]$ExamplesOnly,

    [int]$Jobs = 8,

    # The tests that open a window (ctest label `window`: editor_autotest_*, cli_plugin, cli_player_frames) need a desktop.
    # A shell without one (an SSH session) cannot run them: -NoWindowTests leaves them out of the -Test run, and
    # -WindowTestsOnly (implies -Test) runs only them, from a process that has a desktop. scripts\windows-run-interactive.ps1 does that.
    [switch]$NoWindowTests,
    [switch]$WindowTestsOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Stop-Build([string]$Message) {
    Write-Output "error: $Message"
    exit 1
}

# cmd.exe does the redirection: PowerShell 5.1 would wrap every stderr line of a native program in an error record.
function Invoke-Logged([string]$Log, [string]$CommandLine) {
    cmd /c "$CommandLine > `"$Log`" 2>&1"
    return $LASTEXITCODE
}

# Build slots, shared by every job of this user on this machine (the same limit as scripts/agent-build.sh): at most
# FA_AGENT_MAX_JOBS (default 3) builds or test runs at once, whatever checkout or build dir they come from. A slot is
# the file slot-<n>.lock in FA_AGENT_SLOTS_DIR (default %LOCALAPPDATA%\factoria\agent-build-slots), held open with
# FileShare.None: another job opening it gets a sharing violation, and Windows closes the handle when the process ends,
# however it ends (a killed shell, a crash, a restart), so a dead job never leaves a slot taken. The job names itself
# in slot-<n>.txt (line 1: process id, line 2: build dir) for the jobs that wait; a stale .txt is never read as long as
# its .lock is free.
$script:SlotStream = $null

function Get-SlotsDir {
    if ($env:FA_AGENT_SLOTS_DIR) {
        # Rooted (C:\x, \x, C:x) or relative (taken from the repository root), always normalized.
        if ([IO.Path]::IsPathRooted($env:FA_AGENT_SLOTS_DIR)) { return [IO.Path]::GetFullPath($env:FA_AGENT_SLOTS_DIR) }
        return [IO.Path]::GetFullPath((Join-Path $root $env:FA_AGENT_SLOTS_DIR))
    }
    $base = $env:LOCALAPPDATA
    if (-not $base) { $base = Join-Path $HOME '.cache' }
    return (Join-Path $base 'factoria\agent-build-slots')
}

function Get-MaxJobs {
    $n = 0
    if ($env:FA_AGENT_MAX_JOBS -and [int]::TryParse($env:FA_AGENT_MAX_JOBS, [ref]$n) -and $n -gt 0) { return $n }
    return 3
}

# $true when the exception says that another process holds the file: ERROR_SHARING_VIOLATION (32) or
# ERROR_LOCK_VIOLATION (33). PowerShell on Unix (where the slot logic is tested) reports EAGAIN / EWOULDBLOCK instead.
function Test-SlotHeld($Err) {
    if ($Err -isnot [System.IO.IOException]) { return $false }
    $code = $Err.HResult -band 0xFFFF
    if ($code -in 32, 33) { return $true }
    return ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows -and $code -in 11, 35)
}

# A path relative to the repository root when it is inside it (like agent-build.sh shows the build dirs), else the
# absolute path. Both are normalized first: forward slashes, `..`, a drive root as the repository root.
function Get-ShownPath([string]$Path) {
    try {
        $full = [IO.Path]::GetFullPath($Path)
        $prefix = [IO.Path]::GetFullPath($root).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
        if ($full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -and $full.Length -gt $prefix.Length) {
            return $full.Substring($prefix.Length)
        }
        return $full
    } catch { return $Path }
}

# The build dir named by the holder of a slot, as the waiter shows it ('?' when it cannot be read). The holder writes it
# absolute: the waiter may be in another checkout.
function Read-SlotOwner([string]$Path) {
    try {
        $reader = New-Object System.IO.FileStream($Path, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        try {
            $lines = @((New-Object System.IO.StreamReader($reader, [Text.Encoding]::UTF8)).ReadToEnd() -split "`r?`n")
            if ($lines.Count -ge 2 -and $lines[1]) { return (Get-ShownPath $lines[1]) }
        } finally { $reader.Dispose() }
    } catch { }
    return '?'
}

# Takes a free slot or waits for one. Prints what it waits for once, and how long it waited. When the slots cannot be
# used it says so and returns: the job then builds without the limit, as agent-build.sh does.
function Enter-BuildSlot([string]$Owner, [int]$PollSeconds = 5) {
    $dir = Get-SlotsDir
    $max = Get-MaxJobs
    try {
        [IO.Directory]::CreateDirectory($dir) | Out-Null   # literal: no wildcard in the path is expanded
    } catch {
        Write-Output "note: cannot create ${dir}: building without the job limit"
        return
    }
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $waited = $false
    while ($true) {
        $busy = @()
        for ($i = 1; $i -le $max; $i++) {
            $path = Join-Path $dir "slot-$i.lock"
            $info = Join-Path $dir "slot-$i.txt"
            $stream = $null
            try {
                $stream = New-Object System.IO.FileStream($path, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite,
                    [IO.FileShare]::None)
            } catch {
                # Only a sharing or lock violation (ERROR_SHARING_VIOLATION 32, ERROR_LOCK_VIOLATION 33) means that
                # another job holds the slot; a missing folder, a path that is too long, a full disk or no access is
                # something else and must not make the job wait for ever.
                $err = $_.Exception
                if ($err -is [System.Management.Automation.MethodInvocationException] -and $err.InnerException) {
                    $err = $err.InnerException   # New-Object wraps what the constructor threw
                }
                if (Test-SlotHeld $err) {
                    $busy += (Read-SlotOwner $info)
                    continue
                }
                Write-Output "note: cannot use ${path} ($($err.Message)): building without the job limit"
                return
            }
            $script:SlotStream = $stream
            try {
                $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes("$PID`n$Owner`n")
                $writer = New-Object System.IO.FileStream($info, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::ReadWrite)
                try { $writer.Write($bytes, 0, $bytes.Length) } finally { $writer.Dispose() }
            } catch { }   # the name is only for the jobs that wait
            if ($waited) { Write-Output "waited $([int]$clock.Elapsed.TotalSeconds) s for a build slot ($max jobs at most)" }
            return
        }
        if (-not $waited) {
            $waited = $true
            $list = if ($busy.Count) { $busy -join ' ' } else { '?' }
            Write-Output "waiting for a build slot ($max jobs at most; running: $list)"
        }
        Start-Sleep -Seconds $PollSeconds
    }
}

function Exit-BuildSlot {
    if ($script:SlotStream) {
        $script:SlotStream.Dispose()
        $script:SlotStream = $null
    }
}

$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path
Set-Location -LiteralPath $root
if (-not [IO.Path]::IsPathRooted($BuildDir)) {
    $BuildDir = Join-Path $root $BuildDir
}
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

# Visual Studio 2022 like CI and the presets. vcvars64.bat calls vswhere, so its folder goes on PATH first.
if (-not (Get-Command cl -ErrorAction SilentlyContinue)) {
    $installer = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer'
    $vs = $null
    if (Test-Path -LiteralPath "$installer\vswhere.exe") {
        $vs = & "$installer\vswhere.exe" -latest -products '*' -version '[17.0,18.0)' `
            -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | Select-Object -First 1
    }
    if (-not $vs) {
        Stop-Build "Visual Studio 2022 with the C++ tools was not found (docs/design/BUILDING.md, Windows)."
    }
    $env:PATH = "$installer;$env:PATH"
    cmd /c "`"$vs\VC\Auxiliary\Build\vcvars64.bat`" >nul && set" | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] }
    }
}
foreach ($tool in 'cl', 'cmake', 'ninja', 'ctest') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Stop-Build "$tool not found after loading the MSVC environment. Install the VS 2022 workload 'Desktop development with C++' (it includes CMake and Ninja)."
    }
}

if ($ExamplesOnly) { $Examples = $true }
if ($WindowTestsOnly) { $Test = $true; $Examples = $false }

# Release build of the CLI and `ctest -L example`: the example games run the whole engine for minutes, so they are tests of
# an optimized build (FA_EXAMPLE_TESTS, docs/design/BUILDING_TESTS.md, "Running tests").
function Invoke-ExampleTests {
    $relDir = "$BuildDir-release"
    New-Item -ItemType Directory -Force -Path $relDir | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $relDir 'build.ninja'))) {
        $log = Join-Path $relDir 'agent-configure.log'
        if (Invoke-Logged $log "cmake -S . -B `"$relDir`" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl") {
            Get-Content -LiteralPath $log -Tail 40
            Stop-Build "release configure failed (full log: $log)"
        }
    }
    $log = Join-Path $relDir 'agent-build.log'
    if (Invoke-Logged $log "cmake --build `"$relDir`" -j $Jobs --target factoria") {
        Get-Content -LiteralPath $log -Tail 40
        Stop-Build "release build failed (full log: $log)"
    }
    Write-Output "release build: ok ($relDir)"
    $log = Join-Path $relDir 'agent-ctest.log'
    $rc = Invoke-Logged $log "ctest --test-dir `"$relDir`" -L example -j 3 --output-on-failure"
    Get-Content -LiteralPath $log | Where-Object { $_ -match '\*\*\*|^\d+% tests passed|^Total Test time|^\s+\d+ - .+\(|No tests were found' }
    Write-Output "example tests: $(if ($rc) { 'FAILED' } else { 'ok' }). Full log: $log"
    if ($rc) { exit 1 }
}
# Everything that builds or tests runs inside the slot.
function Invoke-AgentJob {
    if ($ExamplesOnly) { Invoke-ExampleTests; exit 0 }

    if (-not (Test-Path -LiteralPath (Join-Path $BuildDir 'build.ninja'))) {
        $log = Join-Path $BuildDir 'agent-configure.log'
        if (Invoke-Logged $log "cmake --preset windows-ninja-debug -B `"$BuildDir`"") {
            Get-Content -LiteralPath $log -Tail 40
            Stop-Build "configure failed (full log: $log)"
        }
        Write-Output "configure: ok ($BuildDir)"
    }

    $log = Join-Path $BuildDir 'agent-build.log'
    $targets = ''
    if ($Target) {
        $targets = '--target ' + (($Target -split ',' | ForEach-Object { $_.Trim() }) -join ' ')
    }
    $rc = Invoke-Logged $log "cmake --build `"$BuildDir`" -j $Jobs $targets"
    $lines = @(Get-Content -LiteralPath $log)
    # MSVC writes the same header warning once per translation unit. external/ is never edited, so its warnings are noise.
    $warnings = @($lines | Where-Object { $_ -match ': warning [A-Z]*\d+' -and $_ -notmatch '[\\/]external[\\/]' } |
        Select-Object -Unique)
    if ($rc) {
        Write-Output "build: FAILED (exit $rc). Full log: $log"
        $errors = @($lines | Where-Object { $_ -match ': (fatal )?error |error LNK|^FAILED: |CMake Error|ninja: error' } |
            Select-Object -Unique)
        if ($errors.Count) {
            $errors | Select-Object -First 40
            if ($errors.Count -gt 40) { Write-Output "... $($errors.Count - 40) more error lines in the log" }
        } else {
            $lines | Select-Object -Last 40
        }
    } else {
        Write-Output "build: ok"
    }
    if ($warnings.Count) {
        Write-Output "$($warnings.Count) unique warning line(s):"
        $warnings | Select-Object -First 15
    }
    if ($rc) {
        exit 1
    }

    if ($Test -or $Tests) {
        $log = Join-Path $BuildDir $(if ($WindowTestsOnly) { 'agent-ctest-window.log' } else { 'agent-ctest.log' })
        $filter = ''
        if ($Tests) { $filter = "-R `"$Tests`"" }
        if ($NoWindowTests) { $filter += ' -LE window' }
        if ($WindowTestsOnly) { $filter += ' -L window' }
        $rc = Invoke-Logged $log "ctest --test-dir `"$BuildDir`" --output-on-failure $filter"
        $lines = @(Get-Content -LiteralPath $log)
        # A failing test's result line (***Failed, ***Exception, ***Timeout, ***Not Run) is followed by its output, up to
        # the next test's "Start" line or the summary.
        $shown = 0
        foreach ($line in $lines) {
            if ($line -match '^\s*Start\s+\d+:' -or $line -match '^\d+% tests passed') {
                if ($shown -gt 80) { Write-Output "... $($shown - 80) more lines of this test in $log" }
                $shown = 0
            } elseif ($line -cmatch 'Test\s+#\d+: .*\*\*\*') {
                $shown = 1
            } elseif ($shown) {
                $shown++
            }
            if ($shown -ge 1 -and $shown -le 80) { $line }
        }
        $lines | Where-Object { $_ -match '^\d+% tests passed|^Total Test time|^\s+\d+ - .+\(|No tests were found' }
        Write-Output "ctest: $(if ($rc) { 'FAILED' } else { 'ok' }). Full log: $log"
        if ($rc) {
            exit 1
        }
    }

    if ($Examples) { Invoke-ExampleTests }
}

Enter-BuildSlot ([IO.Path]::GetFullPath($BuildDir))   # the absolute build dir names this job to the ones that wait
try {
    Invoke-AgentJob
} finally {
    Exit-BuildSlot
}
