param([string]$TargetPath)

$ErrorActionPreference = 'Stop'
$statePath = Join-Path $PSScriptRoot 'install-state.json'
if (-not (Test-Path -LiteralPath $statePath)) { throw 'No install-state.json found.' }
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
if (-not $TargetPath) { $TargetPath = $state.targetPath }
$TargetPath = (Resolve-Path -LiteralPath $TargetPath).Path
if ($TargetPath -ne $state.targetPath) { throw 'Target path differs from installed hook.' }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $TargetPath).Hash -ne $state.installedHash) {
    throw 'Installed scheduler has changed; refusing to overwrite it.'
}
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $state.backupPath).Hash -ne $state.sourceHash) {
    throw 'Backup hash mismatch; refusing to restore.'
}
[System.IO.File]::WriteAllBytes($TargetPath, [System.IO.File]::ReadAllBytes($state.backupPath))
Remove-Item -LiteralPath $statePath
Write-Output "Restored original scheduler.lua (SHA256 $($state.sourceHash))."
