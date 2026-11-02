#requires -Version 5.1
<#
.SYNOPSIS
    One-time setup of this Windows PC so a Mac can run the native Windows check over SSH (docs/BUILDING.md,
    "Checking Windows from the Mac"). Run it from an ADMINISTRATOR PowerShell. Safe to run again.

        powershell -NoProfile -ExecutionPolicy Bypass -File scripts\setup-windows-remote.ps1 -PublicKey "ssh-ed25519 AAAA... mac" [-RemoteDir C:\path\FactorIA-remote]

    The Mac prints the exact line to paste here: run scripts/setup-windows-remote.sh on the Mac first.

    What it does: installs and starts the OpenSSH Server, opens port 22 on PRIVATE networks only, makes PowerShell the
    SSH shell, authorizes the Mac's key, creates the folder it builds in, checks git, Visual Studio and CMake/Ninja, and prints what to run on the Mac.
#>
[CmdletBinding()]
param(
    # The Mac's public key (the content of ~/.ssh/factoria_windows.pub), one line.
    [Parameter(Mandatory = $true)]
    [string]$PublicKey,

    # The folder the Windows check owns on this PC (a bare repository repo.git the Mac pushes to, and the worktree work
    # where it builds). It needs no clone of FactorIA and never uses one: a folder that is a git repository of its own, or
    # that holds anything else, is refused. Default: %USERPROFILE%\FactorIA-remote.
    [string]$RemoteDir = (Join-Path $env:USERPROFILE 'FactorIA-remote')
)

$ErrorActionPreference = 'Stop'
$problems = New-Object System.Collections.ArrayList

function Step([string]$Text) { Write-Host "==> $Text" }
function Problem([string]$Text) { [void]$problems.Add($Text); Write-Host "!!  $Text" -ForegroundColor Yellow }
# Runs a native program without letting its stderr stop the script: with $ErrorActionPreference = 'Stop', Windows
# PowerShell 5.1 turns any stderr line of a native program into a terminating error. Callers check $LASTEXITCODE.
function Invoke-Native([scriptblock]$Block) {
    $saved = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $Block 2>&1 | ForEach-Object { "$_" } } finally { $ErrorActionPreference = $saved }
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "error: run this from an administrator PowerShell (right-click PowerShell > Run as administrator)." -ForegroundColor Red
    exit 1
}

$PublicKey = $PublicKey.Trim()
if ($PublicKey -notmatch '^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp\d+|sk-ssh-ed25519@openssh\.com) [A-Za-z0-9+/=]+( .*)?$') {
    Write-Host "error: -PublicKey is not a single-line OpenSSH public key (expected 'ssh-ed25519 AAAA... comment')." -ForegroundColor Red
    exit 1
}

# 1. OpenSSH Server.
Step 'OpenSSH Server'
$cap = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' | Select-Object -First 1
if ($null -eq $cap) {
    Write-Host "error: this Windows has no OpenSSH.Server capability (needs Windows 10 1809+ or Windows 11)." -ForegroundColor Red
    exit 1
}
if ($cap.State -ne 'Installed') {
    Write-Host '    installing (needs internet, can take a minute)...'
    Add-WindowsCapability -Online -Name $cap.Name | Out-Null
} else {
    Write-Host '    already installed'
}
Set-Service -Name sshd -StartupType Automatic
if ((Get-Service sshd).Status -ne 'Running') { Start-Service sshd }
Write-Host '    sshd: automatic, running'

# 2. Firewall: port 22 on private networks only. The rule Windows creates itself covers every profile, so it is turned off.
Step 'Firewall (private networks only)'
$builtin = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
if ($builtin) { Disable-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' }
$rule = Get-NetFirewallRule -Name 'FactorIA-sshd-private' -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -Name 'FactorIA-sshd-private' -DisplayName 'FactorIA OpenSSH Server (private networks)' `
        -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -Profile Private | Out-Null
} else {
    Set-NetFirewallRule -Name 'FactorIA-sshd-private' -Enabled True -Profile Private
}
$public = @(Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -ne 'Private' -and $_.IPv4Connectivity -ne 'Disconnected' })
foreach ($p in $public) {
    Problem ("network '{0}' is '{1}', so SSH is blocked on it. If it is your home network, make it private: Set-NetConnectionProfile -InterfaceIndex {2} -NetworkCategory Private" -f $p.Name, $p.NetworkCategory, $p.InterfaceIndex)
}

# 3. PowerShell as the SSH shell (the Mac sends PowerShell commands). -c is the option sshd passes for it.
Step 'Default SSH shell: PowerShell'
$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
New-Item -Path 'HKLM:\SOFTWARE\OpenSSH' -Force | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\OpenSSH' -Name DefaultShell -Value $ps -PropertyType String -Force | Out-Null
Write-Host "    $ps"

# 4. The Mac's key. sshd reads administrators_authorized_keys instead of the user's file for members of Administrators,
# and ignores it unless only SYSTEM and Administrators can write it.
Step 'Mac key'
# By SID (S-1-5-32-544), not by name: the group is "Administradores", "Administrateurs"... on a localized Windows.
$userIsAdmin = @($identity.Groups | Where-Object { $_.Value -eq 'S-1-5-32-544' }).Count -gt 0
if ($userIsAdmin) {
    $keyFile = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
} else {
    $sshDir = Join-Path $env:USERPROFILE '.ssh'
    New-Item -ItemType Directory -Force -Path $sshDir | Out-Null
    $keyFile = Join-Path $sshDir 'authorized_keys'
}
New-Item -ItemType Directory -Force -Path (Split-Path $keyFile -Parent) | Out-Null
$existing = @()
if (Test-Path -LiteralPath $keyFile) { $existing = @(Get-Content -LiteralPath $keyFile) }
$keyBody = ($PublicKey -split ' ')[1]
if (-not ($existing | Where-Object { $_ -like "*$keyBody*" })) {
    $all = @($existing | Where-Object { $_.Trim() -ne '' }) + $PublicKey
    # ASCII without BOM: sshd does not read a BOM.
    [IO.File]::WriteAllText($keyFile, (($all -join "`r`n") + "`r`n"), (New-Object Text.ASCIIEncoding))
    Write-Host "    key added to $keyFile"
} else {
    Write-Host "    key already in $keyFile"
}
if ($userIsAdmin) {
    Invoke-Native { icacls.exe $keyFile /inheritance:r /grant '*S-1-5-32-544:F' /grant '*S-1-5-18:F' } | Out-Null
} else {
    Invoke-Native { icacls.exe $keyFile /inheritance:r /grant "${env:USERNAME}:F" /grant '*S-1-5-18:F' } | Out-Null
}
if ($LASTEXITCODE -ne 0) { Problem "icacls failed on $keyFile; sshd will ignore the key until only SYSTEM, Administrators and you can write it." }
Restart-Service sshd

# 5. git, the folder the check owns, and what agent-build.ps1 needs.
Step 'git, the check folder and the build tools'
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Problem 'git is not installed: winget install --id Git.Git -e   (the check pushes the Mac commit with git)'
} else {
    Write-Host "    $(& git --version)"
    $repoGit = Join-Path $RemoteDir 'repo.git'
    if (Test-Path -LiteralPath (Join-Path $RemoteDir '.git')) {
        Problem "$RemoteDir is a git repository of its own, so the check will refuse to use it. Run this again with -RemoteDir <a new or empty folder>."
    } elseif (-not (Test-Path -LiteralPath $repoGit)) {
        if ((Test-Path -LiteralPath $RemoteDir) -and @(Get-ChildItem -LiteralPath $RemoteDir -Force).Count -gt 0) {
            Problem "$RemoteDir exists, is not empty and is not a FactorIA-remote folder, so the check will refuse to use it. Run this again with -RemoteDir <a new or empty folder>."
        } else {
            New-Item -ItemType Directory -Force -Path $RemoteDir | Out-Null
            Invoke-Native { git init --bare -q $repoGit } | Out-Null
            Write-Host "    created $repoGit"
        }
    } else {
        Write-Host "    check folder: $RemoteDir"
    }
}
# agent-build.ps1: Visual Studio 2022 with the C++ tools found by vswhere; it takes cmake, ninja and ctest from the
# MSVC environment (vcvars64.bat), where Visual Studio's own CMake and Ninja components put them.
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsPath = $null
if (Test-Path -LiteralPath $vswhere) {
    $vsPath = & $vswhere -latest -products '*' -version '[17.0,18.0)' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath | Select-Object -First 1
}
if (-not $vsPath) {
    Problem 'Visual Studio 2022 with the C++ tools was not found. Install it: winget install --id Microsoft.VisualStudio.2022.BuildTools -e --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.CMake.Project --includeRecommended"'
} else {
    Write-Host "    Visual Studio: $vsPath"
    $cmakeBin = Join-Path $vsPath 'Common7\IDE\CommonExtensions\Microsoft\CMake'
    $haveCMake = (Test-Path -LiteralPath (Join-Path $cmakeBin 'CMake\bin\cmake.exe')) -or (Get-Command cmake -ErrorAction SilentlyContinue)
    $haveNinja = (Test-Path -LiteralPath (Join-Path $cmakeBin 'Ninja\ninja.exe')) -or (Get-Command ninja -ErrorAction SilentlyContinue)
    if (-not ($haveCMake -and $haveNinja)) {
        Problem ("CMake or Ninja is missing from that Visual Studio. Add the component: & '{0}' modify --installPath '{1}' --add Microsoft.VisualStudio.Component.VC.CMake.Project --passive" -f (Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\setup.exe'), $vsPath)
    } else {
        Write-Host '    cmake and ninja: found'
    }
}
if (-not (Get-Command ccache -ErrorAction SilentlyContinue)) {
    Write-Host '    ccache: not installed (optional, makes the Release example build faster: winget install --id Ccache.Ccache -e)'
}

# 6. What to run on the Mac.
$ips = @(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*' -and $_.PrefixOrigin -ne 'WellKnown' } |
    ForEach-Object { $_.IPAddress })
$ip = if ($ips.Count) { $ips[0] } else { '<this PC IP>' }
Write-Host ''
Write-Host "PC: $env:COMPUTERNAME   user: $env:USERNAME   LAN IP(s): $($ips -join ', ')"
if ($problems.Count) {
    Write-Host ''
    Write-Host "Fix the $($problems.Count) warning(s) above (then run this script again if needed). The Mac side can already be set up."
}
Write-Host ''
Write-Host 'Now, on the Mac, run:'
Write-Host ''
$repoArg = ''
if ($RemoteDir -ne "C:\Users\$env:USERNAME\FactorIA-remote") { $repoArg = " --repo '$RemoteDir'" }
Write-Host "    scripts/setup-windows-remote.sh --host $ip --user $env:USERNAME$repoArg"
Write-Host ''
exit 0
