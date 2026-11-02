<#
.SYNOPSIS
  Runs the windowed tests (ctest label "window") in the desktop session of the user who is logged in on this PC.

.DESCRIPTION
  An SSH session on Windows has no desktop, so a D3D11 swap chain cannot be created there and the editor / player tests
  fail. This script, started from SSH by scripts/ci-remote-windows.sh, registers a one-shot scheduled task that runs
  scripts\agent-build.ps1 -WindowTestsOnly as the console user with an interactive logon (it runs in that user's
  session, on their desktop, with a hidden console), waits for it, prints its output and exits with its exit code. The
  task is always deleted afterwards, also when this script is stopped or times out. It does not touch power or sleep
  settings, and never wakes or logs in anything.

  Exit codes: the exit code of the tests (0 = all passed); 78 = nobody is logged in on the PC desktop, so the tests
  were NOT run; 79 = the task did not finish within -TimeoutSeconds (it is stopped).
#>
param(
    [Parameter(Mandatory = $true)][string]$WorkDir,
    [string]$BuildDir = 'build\agent-preflight',
    [int]$TimeoutSeconds = 1800
)
$ErrorActionPreference = 'Stop'

$user = (Get-CimInstance Win32_ComputerSystem).UserName
if (-not $user) {
    Write-Output 'NO-INTERACTIVE-USER: nobody is logged in on the PC desktop.'
    exit 78
}

$work = (Resolve-Path -LiteralPath $WorkDir).Path
$tmp = Join-Path $work 'build\interactive-run'
New-Item -ItemType Directory -Force $tmp | Out-Null
$log = Join-Path $tmp 'output.log'
$rcFile = Join-Path $tmp 'exit-code.txt'
$wrapper = Join-Path $tmp 'run.ps1'
Remove-Item -Force -ErrorAction SilentlyContinue $log, $rcFile

# What the task runs, inside the user's session. The exit code is written last, so its presence means "finished".
$body = @"
`$ErrorActionPreference = 'Continue'
Set-Location -LiteralPath '$work'
`$rc = 1
try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File scripts\agent-build.ps1 '$BuildDir' -WindowTestsOnly *>&1 | Out-File -Encoding utf8 -FilePath '$log'
    `$rc = `$LASTEXITCODE
} catch { `$_ | Out-File -Append -Encoding utf8 -FilePath '$log' }
Set-Content -Path '$rcFile' -Value `$rc
"@
Set-Content -Path $wrapper -Value $body -Encoding utf8

$name = 'FactorIA-remote-window-tests'
Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue
$exitCode = 79
try {
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' `
        -Argument ('-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $wrapper + '"')
    $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
        -ExecutionTimeLimit (New-TimeSpan -Seconds ($TimeoutSeconds + 120))
    Register-ScheduledTask -TaskName $name -Action $action -Principal $principal -Settings $settings | Out-Null
    Write-Output "== windowed tests: running as $user in their desktop session (task $name, deleted afterwards)"
    Start-ScheduledTask -TaskName $name

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $nextNote = (Get-Date).AddSeconds(30)
    while (-not (Test-Path -LiteralPath $rcFile) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 2
        if ((Get-Date) -ge $nextNote) { Write-Output '   ... still running'; $nextNote = (Get-Date).AddSeconds(30) }
    }
    if (Test-Path -LiteralPath $rcFile) {
        if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log }
        $exitCode = [int]((Get-Content -LiteralPath $rcFile -Raw).Trim())
    } else {
        Write-Output "windowed tests: the task did not finish within $TimeoutSeconds s; stopping it."
        if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log -Tail 40 }
        $exitCode = 79
    }
} finally {
    Stop-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
    Unregister-ScheduledTask -TaskName $name -Confirm:$false -ErrorAction SilentlyContinue
}
exit $exitCode
