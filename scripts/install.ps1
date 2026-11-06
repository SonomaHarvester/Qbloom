[CmdletBinding()]
param(
    [string]$Source = (Join-Path $PSScriptRoot 'bin'),
    [switch]$InstallSwift
)

$ErrorActionPreference = 'Stop'
$exe = Join-Path $Source 'qbloom.exe'
$bundle = 'qbloom_QbloomCLI.bundle'
if (!(Test-Path -LiteralPath $exe -PathType Leaf) -or
    !(Test-Path -LiteralPath (Join-Path $Source $bundle) -PathType Container)) {
    throw 'The release executable and template bundle are required. Extract the Windows ZIP or pass -Source with the SwiftPM release output directory.'
}

function Test-Qbloom {
    param([string]$Executable)
    $process = Start-Process -FilePath $Executable -ArgumentList '--version' -WindowStyle Hidden -Wait -PassThru
    return $process.ExitCode
}

$status = Test-Qbloom $exe
# STATUS_DLL_NOT_FOUND and STATUS_ENTRYPOINT_NOT_FOUND.
if ($status -in @(-1073741515, -1073741511)) {
    if (!$InstallSwift) {
        throw 'A required runtime DLL is missing or incompatible. Run this script with -InstallSwift to install Swift 6.4.2 via WinGet, then retry the executable.'
    }
    $winget = Get-Command winget.exe -CommandType Application -ErrorAction SilentlyContinue
    if (!$winget) {
        throw 'WinGet is unavailable. Install Swift 6.4.2 from https://www.swift.org/install/windows/ and rerun this script.'
    }
    & $winget.Source install --id Swift.Toolchain --exact --version 6.4.2 --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "Swift installation failed with exit code $LASTEXITCODE." }
    $env:Path = @(
        [Environment]::GetEnvironmentVariable('Path', 'Machine')
        [Environment]::GetEnvironmentVariable('Path', 'User')
        $env:Path
    ) -join ';'
    $status = Test-Qbloom $exe
}
if ($status -ne 0) { throw "Qbloom could not start (exit code $status). Check the release architecture and runtime requirements." }

$root = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Qbloom'
$bin = Join-Path $root 'bin'
New-Item -ItemType Directory -Path $root -Force | Out-Null
foreach ($path in @($root, $bin)) {
    if (Test-Path -LiteralPath $path) {
        $item = Get-Item -LiteralPath $path -Force
        if (!$item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Expected a regular directory at $path."
        }
    }
}

$stage = Join-Path $root ('stage-' + [guid]::NewGuid().ToString('N'))
$backup = Join-Path $root ('backup-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null
Copy-Item -LiteralPath $exe, (Join-Path $Source $bundle) -Destination $stage -Recurse
if ((Test-Qbloom (Join-Path $stage 'qbloom.exe')) -ne 0) { throw "Staged executable failed. Staging directory: $stage" }

$previous = Test-Path -LiteralPath $bin
if ($previous) { Move-Item -LiteralPath $bin -Destination $backup }
try {
    Move-Item -LiteralPath $stage -Destination $bin
} catch {
    if ($previous -and !(Test-Path -LiteralPath $bin)) {
        Move-Item -LiteralPath $backup -Destination $bin
    }
    throw
}

$userPath = [string][Environment]::GetEnvironmentVariable('Path', 'User')
$entries = $userPath -split ';' | ForEach-Object {
    [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\')
}
if ($entries -notcontains $bin) {
    $updated = ($userPath.TrimEnd(';'), $bin | Where-Object { $_ }) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $updated, 'User')
}
Write-Output "Installed Qbloom at $bin. Open a new PowerShell and run qbloom --help."
if ($previous) { Write-Output "Previous installation saved at $backup." }
