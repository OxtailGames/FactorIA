# Fetches the D3D12 Agility SDK runtime for the Windows CI job (M79, .github/workflows/ci.yml, "D3D12 Agility SDK runtime"): the
# pinned NuGet package Microsoft.Direct3D.D3D12, checked against its SHA-256 and unpacked to -Out as the two DLLs the ctest
# render_d3d12_raytracing runs on (D3D12Core.dll, d3d12SDKLayers.dll; x64) and the package's licence. CI-only: nothing of it
# reaches a game, the editor or a release.
#
#   pwsh tools/ci/agility/fetch_agility.ps1 -Version 1.620.2 -Sha256 <hex> -Cache ~/agility-nupkg/agility.nupkg -Out $env:RUNNER_TEMP/agility
#
# -Cache is the folder the job caches: a file there that is not the pinned one (a cache entry saved from a cut-off run) is
# downloaded again, and the download is written as .part and renamed once its SHA-256 matches, so the cached file is never a
# partial or a wrong one. The SDK version the program has to export (D3D12SDKVersion) is the middle number of the package
# version (1.620.2 is 620); it is printed as `sdkVersion=620`, and written to $GITHUB_ENV as FA_AGILITY_SDK_VERSION with
# FA_AGILITY_DIR when that file is set.
param(
    [Parameter(Mandatory)][string]$Version,
    [Parameter(Mandatory)][string]$Sha256,
    [Parameter(Mandatory)][string]$Cache,
    [Parameter(Mandatory)][string]$Out
)
$ErrorActionPreference = 'Stop'
$Sha256 = $Sha256.ToLower()
New-Item -ItemType Directory -Force (Split-Path $Cache) | Out-Null
$url = "https://api.nuget.org/v3-flatcontainer/microsoft.direct3d.d3d12/$Version/microsoft.direct3d.d3d12.$Version.nupkg"
$part = "$Cache.part"
if ((Test-Path $Cache) -and ((Get-FileHash $Cache -Algorithm SHA256).Hash.ToLower() -ne $Sha256)) {
    Write-Host "::warning title=Agility download::the cached package is not the pinned file: downloading it again"
    Remove-Item $Cache
}
if (-not (Test-Path $Cache)) {
    # nuget.org blinks now and then: four tries, a few seconds apart, before the step (and the job) fails.
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        try {
            Invoke-WebRequest $url -OutFile $part
            break
        } catch {
            Remove-Item $part -ErrorAction SilentlyContinue
            if ($attempt -eq 4) { throw }
            Write-Host "::warning title=Agility download::attempt $attempt of 4 failed: $($_.Exception.Message)"
            Start-Sleep -Seconds (5 * $attempt)
        }
    }
    $hash = (Get-FileHash $part -Algorithm SHA256).Hash.ToLower()
    if ($hash -ne $Sha256) { Remove-Item $part; throw "Microsoft.Direct3D.D3D12 $Version is not the pinned file (SHA-256 $hash, pinned $Sha256)" }
    Move-Item $part $Cache -Force
}
$unpacked = "$Out-unpacked"
Copy-Item $Cache "$Cache.zip" -Force
Expand-Archive "$Cache.zip" $unpacked -Force
New-Item -ItemType Directory -Force $Out | Out-Null
foreach ($dll in 'D3D12Core.dll', 'd3d12SDKLayers.dll') {
    Copy-Item "$unpacked\build\native\bin\x64\$dll" $Out -Force
}
Copy-Item "$unpacked\LICENSE.txt" $Out -Force
$sdk = $Version.Split('.')[1]
Write-Host "sdkVersion=$sdk"
if ($env:GITHUB_ENV) {
    "FA_AGILITY_DIR=$Out" | Out-File -Append -Encoding utf8 $env:GITHUB_ENV
    "FA_AGILITY_SDK_VERSION=$sdk" | Out-File -Append -Encoding utf8 $env:GITHUB_ENV
}
