#requires -Version 5.1
<#
.SYNOPSIS
    Configure, build and (optionally) test FactorIA on Windows.

.DESCRIPTION
    Uses the presets in CMakePresets.json. Build trees go to build\<preset>.
    The default preset is windows-<Config> (Visual Studio 2022, x64).
    CMake (3.24 or newer) is taken from PATH; without one, the CMake that Visual Studio installs is found with vswhere
    (Build Tools too), so a machine whose only CMake is that one builds. A checkout in a folder too deep for Windows'
    260-character path limit gets a warning.

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

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'

# Visual Studio installs its own CMake (component "C++ CMake tools for Windows", part of the workload "Desktop development
# with C++") in a folder that is not on PATH. VS 2022 first: that is the generator the presets use. Build Tools count.
function Find-VisualStudioCmake {
    if (-not (Test-Path -LiteralPath $vswhere)) {
        return $null
    }
    foreach ($range in @('[17.0,18.0)', '[17.0,)')) {
        $found = & $vswhere -latest -products '*' -version $range -requires Microsoft.VisualStudio.Component.VC.CMake.Project `
            -find 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe' | Select-Object -First 1
        if ($found -and (Test-Path -LiteralPath $found)) {
            return [string]$found
        }
    }
    return $null
}

# "3.31.6" -> [version]; $null when the program does not run or prints something else.
function Get-CmakeVersion([string]$Exe) {
    $line = & $Exe --version 2>$null | Select-Object -First 1
    if ($line -match 'version (\d+\.\d+(\.\d+)?)') {
        return [version]$Matches[1]
    }
    return $null
}

$minCmake = [version]'3.24'
$cmakeExe = $null
$cmakeFrom = $null
$onPath = Get-Command cmake -ErrorAction SilentlyContinue
if ($onPath) {
    $v = Get-CmakeVersion $onPath.Source
    if ($v -and $v -ge $minCmake) {
        $cmakeExe, $cmakeFrom = $onPath.Source, 'on PATH'
    } else {
        Write-Host "warning: the cmake on PATH ($($onPath.Source)) is $v; FactorIA needs $minCmake or newer. Looking for the one of Visual Studio." -ForegroundColor Yellow
    }
}
if (-not $cmakeExe) {
    $vsCmake = Find-VisualStudioCmake
    if ($vsCmake) {
        $v = Get-CmakeVersion $vsCmake
        if ($v -and $v -ge $minCmake) {
            $cmakeExe, $cmakeFrom = $vsCmake, 'installed by Visual Studio, found with vswhere'
            # cmake and ctest both come from this folder; the presets and `cmake --build` use whichever is first on PATH.
            $env:PATH = "$(Split-Path -Parent $vsCmake);$env:PATH"
        }
    }
}
if (-not $cmakeExe) {
    Stop-Build ("cmake $minCmake or newer not found (not on PATH, and Visual Studio's CMake was not found either). " +
        "Install Visual Studio 2022 with the 'Desktop development with C++' workload (it includes CMake), or run: " +
        "winget install Kitware.CMake. Then open a new terminal.")
}
Write-Host "==> cmake: $cmakeExe (CMake $(Get-CmakeVersion $cmakeExe), $cmakeFrom)"

function Test-VisualStudio2022 {
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

# ---- path length ------------------------------------------------------------

# Many Windows tools (MSBuild's file tracker, cl.exe, rc.exe) stop at MAX_PATH, 259 characters. A Visual Studio build writes
# files as deep as build\windows-debug\engine\render\fa_render.dir\Debug\fa_render.tlog\... below the checkout: the deepest
# path a build of the windows presets creates measures $deepestBuildPath characters (relative to the repository root, with
# the folder separator). Only warns: the build may work (for example with long paths enabled).
$deepestBuildPath = 190
$maxPath = 259
$root = (Get-Location).Path
if ($Preset -notlike 'windows-ninja*' -and ($root.Length + $deepestBuildPath) -gt $maxPath) {
    $room = $maxPath - $deepestBuildPath
    Write-Host ("warning: this checkout is in a deep folder ($($root.Length) characters: $root). The longest file a build " +
        "creates adds $deepestBuildPath, so $($root.Length + $deepestBuildPath) in all, and Windows tools stop at $maxPath. " +
        "MSBuild may fail with FTK1011 ('The specified path, file name, or both are too long') or the compiler with C1083. " +
        "Fix: clone the repository to a short path, such as C:\src\FactorIA (the folder of the checkout must stay under $room " +
        "characters), or turn on Windows long paths (LongPathsEnabled=1 in the registry, and git config --system " +
        "core.longpaths true); some tools ignore it, so the short path is the sure fix.") -ForegroundColor Yellow
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
