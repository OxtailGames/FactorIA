#requires -Version 5.1
<#
.SYNOPSIS
    Build (and test) a Ninja + MSVC Debug tree from any shell, printing only what matters.

.DESCRIPTION
    For AI agents (and anyone) on Windows: one call, no Developer prompt and no wrapper script needed. It loads the
    Visual Studio 2022 C++ environment when cl.exe is not on PATH, configures the build directory with the
    windows-ninja-debug preset on first use, builds it and, with -Test or -Tests, runs ctest (serially, as CI does).
    Full logs go to <BuildDir>\agent-configure.log, agent-build.log and agent-ctest.log. The console gets the errors,
    the unique warnings, each failing test with its output, and the ctest summary. Exit code 0 means everything passed.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts\agent-build.ps1 build\agent-<name> [-Target fa_test_core[,fa_test_scene]] [-Test] [-Tests <ctest -R regex>] [-Jobs 8]

.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\agent-build.ps1 build\agent-physics -Target fa_test_physics -Tests physics
.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File scripts\agent-build.ps1 build\dev -Test
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

    [int]$Jobs = 8
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
        Stop-Build "Visual Studio 2022 with the C++ tools was not found (docs/BUILDING.md, Windows)."
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
$watch = [Diagnostics.Stopwatch]::StartNew()
$rc = Invoke-Logged $log "cmake --build `"$BuildDir`" -j $Jobs $targets"
$lines = @(Get-Content -LiteralPath $log)
# MSVC writes the same header warning once per translation unit. external/ is never edited, so its warnings are noise.
$warnings = @($lines | Where-Object { $_ -match ': warning [A-Z]*\d+' -and $_ -notmatch '[\\/]external[\\/]' } |
    Select-Object -Unique)
if ($rc) {
    Write-Output "build: FAILED (exit $rc) after $([int]$watch.Elapsed.TotalSeconds) s. Full log: $log"
    $errors = @($lines | Where-Object { $_ -match ': (fatal )?error |error LNK|^FAILED: |CMake Error|ninja: error' } |
        Select-Object -Unique)
    if ($errors.Count) {
        $errors | Select-Object -First 40
        if ($errors.Count -gt 40) { Write-Output "... $($errors.Count - 40) more error lines in the log" }
    } else {
        $lines | Select-Object -Last 40
    }
} else {
    Write-Output "build: ok in $([int]$watch.Elapsed.TotalSeconds) s"
}
if ($warnings.Count) {
    Write-Output "$($warnings.Count) unique warning line(s):"
    $warnings | Select-Object -First 15
}
if ($rc) {
    exit 1
}

if ($Test -or $Tests) {
    $log = Join-Path $BuildDir 'agent-ctest.log'
    $filter = ''
    if ($Tests) { $filter = "-R `"$Tests`"" }
    $watch.Restart()
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
    Write-Output "ctest: $(if ($rc) { 'FAILED' } else { 'ok' }) in $([int]$watch.Elapsed.TotalSeconds) s. Full log: $log"
    if ($rc) {
        exit 1
    }
}
