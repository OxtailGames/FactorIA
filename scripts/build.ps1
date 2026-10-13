#requires -Version 5.1
<#
.SYNOPSIS
    Configure, build and (optionally) test FactorIA on Windows.

.DESCRIPTION
    Uses the presets in CMakePresets.json. Build trees go to build\<preset>.
    The default preset is windows-<Config> (Visual Studio 2022, x64).

    Run from the repository root:
        powershell -ExecutionPolicy Bypass -File .\scripts\build.ps1 [debug|release] [-Test] [-Preset NAME]

.PARAMETER Config
    debug (default) or release.

.PARAMETER Test
    Run the test suite (ctest) after building.

.PARAMETER Preset
    Use this preset instead of windows-<Config>, e.g. windows-ninja-debug.
    windows-ninja-debug needs cl.exe on PATH: run it from "Developer PowerShell for VS 2022".

.EXAMPLE
    .\scripts\build.ps1
.EXAMPLE
    .\scripts\build.ps1 release -Test
.EXAMPLE
    .\scripts\build.ps1 -Preset windows-ninja-debug
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('debug', 'release')]
    [string]$Config = 'debug',

    [switch]$Test,

    [string]$Preset
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Stop-Build([string]$Message) {
    Write-Host "error: $Message" -ForegroundColor Red
    exit 1
}

# Windows PowerShell 5.1 has no $IsWindows, so check the platform directly.
if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
    Stop-Build 'this script is for Windows. On Linux or macOS use ./scripts/build.sh'
}

Set-Location -LiteralPath (Join-Path $PSScriptRoot '..')

if (-not $Preset) {
    $Preset = "windows-$Config"
}

# ---- prerequisites ----------------------------------------------------------

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    Stop-Build ("cmake not found. Install Visual Studio 2022 with the 'Desktop development with C++' " +
        "workload (it includes CMake), or run: winget install Kitware.CMake. Then open a new terminal.")
}

$firstLine = (cmake --version)[0]
if ($firstLine -match 'version (\d+)\.(\d+)') {
    $major = [int]$Matches[1]
    $minor = [int]$Matches[2]
    if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 24)) {
        Stop-Build "CMake $major.$minor is too old. FactorIA needs CMake 3.24 or newer."
    }
}

function Test-VisualStudio2022 {
    $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (-not (Test-Path -LiteralPath $vswhere)) {
        return $false
    }
    $installPath = & $vswhere -latest -version '[17.0,18.0)' -products '*' `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    return [bool]$installPath
}

if ($Preset -like 'windows-ninja*') {
    if (-not (Get-Command cl -ErrorAction SilentlyContinue)) {
        Stop-Build ("cl.exe not found. The preset '$Preset' needs the MSVC compiler on PATH. " +
            "Open 'Developer PowerShell for VS 2022' and run the script there, or drop -Preset to use the default.")
    }
} elseif (-not (Test-VisualStudio2022)) {
    Stop-Build ("Visual Studio 2022 with the C++ tools was not found. Install 'Desktop development with C++' " +
        "from https://visualstudio.microsoft.com/downloads/ , or use -Preset windows-ninja-debug " +
        "from a Developer PowerShell.")
}

# ---- configure, build, test -------------------------------------------------

Write-Host "==> FactorIA preset: $Preset"

Write-Host "==> configure: cmake --preset $Preset"
& cmake --preset $Preset
if ($LASTEXITCODE -ne 0) {
    Stop-Build "configure failed for preset '$Preset'. Presets usable on this machine: cmake --list-presets"
}

Write-Host "==> build: cmake --build --preset $Preset"
& cmake --build --preset $Preset
if ($LASTEXITCODE -ne 0) {
    Stop-Build "build failed for preset '$Preset' (see the first error above)"
}

if ($Test) {
    Write-Host "==> test: ctest --preset $Preset"
    & ctest --preset $Preset
    if ($LASTEXITCODE -ne 0) {
        Stop-Build "tests failed for preset '$Preset' (output above)"
    }
}

Write-Host "==> done. Build tree: build\$Preset"
