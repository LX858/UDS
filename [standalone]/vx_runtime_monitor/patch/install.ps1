param(
    [string]$TargetPath,
    [string]$ApprovedSourceHash
)

$ErrorActionPreference = 'Stop'
if (-not $TargetPath) {
    $TargetPath = 'C:\Users\Administrator\Desktop\UNS\antifact\citizen\scripting\lua\scheduler.lua'
}
$TargetPath = [System.IO.Path]::GetFullPath($TargetPath)
if (-not (Test-Path -LiteralPath $TargetPath -PathType Leaf)) {
    throw "Artifact scheduler not found: $TargetPath. Install the resource on the artifact host or pass -TargetPath."
}
$TargetPath = (Resolve-Path -LiteralPath $TargetPath).Path
$statePath = Join-Path $PSScriptRoot 'install-state.json'
$currentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $TargetPath).Hash
$knownSourceHashes = @(
    'A533B4C61A28A144ACB3C04BFC5DF7EA19193CBC2FED266A0F7FF5AFC176805C',
    '1CCAF7DBF8BD05E838B289D0DA677EFCD8E0A4DA5ABEF0CA6A9FFFDDD6FD632D'
)
$bytes = [System.IO.File]::ReadAllBytes($TargetPath)
$source = [System.Text.Encoding]::UTF8.GetString($bytes)

if ($source.Contains('VX_RUNTIME_MONITOR_HOOK_V1_BEGIN')) {
    if (-not (Test-Path -LiteralPath $statePath)) { throw 'Found hook marker but no install-state.json; refusing to modify.' }
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($state.targetPath -ne $TargetPath -or $state.installedHash -ne $currentHash) {
        throw 'Hooked scheduler differs from the recorded installation; refusing to modify.'
    }
    Write-Output "Hook already installed: $TargetPath"
    exit 0
}

if ($currentHash -notin $knownSourceHashes -and
    (-not $ApprovedSourceHash -or $currentHash -ne $ApprovedSourceHash.ToUpperInvariant())) {
    throw "Unexpected scheduler SHA256 $currentHash. Review this artifact and pass -ApprovedSourceHash explicitly before patching."
}

$script:body = $source.Replace("`r`n", "`n")
function Replace-Once([string]$old, [string]$new) {
    $old = $old.Replace("`r`n", "`n")
    $new = $new.Replace("`r`n", "`n")
    $at = $script:body.IndexOf($old, [StringComparison]::Ordinal)
    if ($at -lt 0 -or $script:body.IndexOf($old, $at + $old.Length, [StringComparison]::Ordinal) -ge 0) {
        throw "Missing or ambiguous scheduler anchor: $($old.Substring(0, [Math]::Min(70, $old.Length)))"
    }
    $script:body = $script:body.Substring(0, $at) + $new + $script:body.Substring($at + $old.Length)
}

$hook = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'scheduler-hook.lua') -Raw).TrimEnd().Replace("`r`n", "`n")
Replace-Once 'ClearTimeout = Citizen.ClearTimeout' ("ClearTimeout = Citizen.ClearTimeout`n`n" + $hook)

Replace-Once @'
	local data = msgpack_unpack(eventPayload)
'@ @'
	local data = msgpack_unpack(eventPayload)
	local monitorStatus = 'unhandled'
	if eventHandlerEntry and eventHandlerEntry.handlers then
		monitorStatus = eventSource:sub(1, 3) == 'net' and not eventHandlerEntry.safeForNet and 'blocked' or 'ok'
	end
	vxMonitorPush('event', 'receive', eventName, vxMonitorResource, vxMonitorPlayer(eventSource), eventPayload:len(), nil, monitorStatus)
'@

Replace-Once @'
						handler(table_unpack(data))
'@ @'
						if vxMonitorEnabled and not vxMonitorIgnore(eventName) then
							local started = GetGameTimer()
							local ok, err = xpcall(handler, debug.traceback, table_unpack(data))
							vxMonitorPush('event', 'handler', eventName, vxMonitorResource,
								vxMonitorPlayer(eventSource), eventPayload:len(), GetGameTimer() - started,
								ok and 'ok' or 'error')
							if not ok then error(err, 0) end
						else
							handler(table_unpack(data))
						end
'@

Replace-Once @'
	RegisterResourceAsEventHandler(eventName)
'@ @'
	RegisterResourceAsEventHandler(eventName)
	vxMonitorPush('event', 'register', eventName, nil, nil, nil, nil, 'ok')
'@

Replace-Once @'
	eventHandlers[eventData.name].handlers[eventData.key] = nil
'@ @'
	eventHandlers[eventData.name].handlers[eventData.key] = nil
	vxMonitorPush('event', 'unregister', eventData.name, nil, nil, nil, nil, 'ok')
'@

Replace-Once @'
		tableEntry.safeForNet = true
'@ @'
		tableEntry.safeForNet = true
		vxMonitorPush('event', 'net-register', eventName, nil, nil, nil, nil, 'ok')
'@

Replace-Once @'
function TriggerEvent(eventName, ...)
	local payload = msgpack_pack_args(...)
'@ @'
function TriggerEvent(eventName, ...)
	local payload = msgpack_pack_args(...)
	vxMonitorPush('event', 'send-local', eventName, nil, _G.source, payload:len(), nil, 'ok')
'@

Replace-Once @'
	function TriggerClientEvent(eventName, playerId, ...)
		local payload = msgpack_pack_args(...)
'@ @'
	function TriggerClientEvent(eventName, playerId, ...)
		local payload = msgpack_pack_args(...)
		vxMonitorPush('event', 'send-client', eventName, nil, playerId, payload:len(), nil,
			playerId == -1 and 'broadcast' or 'ok')
'@

Replace-Once @'
	function TriggerLatentClientEvent(eventName, playerId, bps, ...)
		local payload = msgpack_pack_args(...)
'@ @'
	function TriggerLatentClientEvent(eventName, playerId, bps, ...)
		local payload = msgpack_pack_args(...)
		vxMonitorPush('event', 'send-latent', eventName, nil, playerId, payload:len(), nil,
			playerId == -1 and 'broadcast' or 'ok')
'@

Replace-Once @'
		local exportName = GetResourceMetadata(resource, exportKey, i)
'@ @'
		local exportName = GetResourceMetadata(resource, exportKey, i)
		vxMonitorPush('export', 'register', exportName, nil, nil, nil, nil, 'ok')
'@

Replace-Once 'setCB(_G[exportName])' 'setCB(vxMonitorWrapExport(exportName, _G[exportName]))'

Replace-Once @'
				return exportProcessResult(resource, k2, pcall(exportsCallbackCache[resource][k2], ...))
'@ @'
				local started = vxMonitorEnabled and GetGameTimer() or nil
				local result = table_pack(pcall(exportsCallbackCache[resource][k2], ...))
				if vxMonitorEnabled then
					vxMonitorPush('export', 'call', k2, resource, _G.source, nil,
						GetGameTimer() - started, result[1] and 'ok' or 'error')
				end
				return exportProcessResult(resource, k2, table_unpack(result, 1, result.n))
'@

Replace-Once @'
			setCB(func)
'@ @'
			setCB(vxMonitorWrapExport(exportName, func))
'@

Replace-Once @'
	__call = function(t, exportName, func)
		AddEventHandler(getExportEventName(GetCurrentResourceName(), exportName), function(setCB)
'@ @'
	__call = function(t, exportName, func)
		vxMonitorPush('export', 'register', exportName, nil, nil, nil, nil, 'ok')
		AddEventHandler(getExportEventName(GetCurrentResourceName(), exportName), function(setCB)
'@

$patched = $script:body.Replace("`n", "`r`n")
$backupDir = Join-Path $PSScriptRoot 'backups'
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
$backupPath = Join-Path $backupDir ("scheduler.$currentHash.lua")
if (-not (Test-Path -LiteralPath $backupPath)) { [System.IO.File]::WriteAllBytes($backupPath, $bytes) }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $backupPath).Hash -ne $currentHash) {
    throw 'Backup hash mismatch; scheduler was not modified.'
}
try {
    [System.IO.File]::WriteAllText($TargetPath, $patched, [System.Text.UTF8Encoding]::new($false))
    $installedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $TargetPath).Hash
    @{ targetPath = $TargetPath; sourceHash = $currentHash; installedHash = $installedHash; backupPath = $backupPath } |
        ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding utf8
} catch {
    [System.IO.File]::WriteAllBytes($TargetPath, $bytes)
    throw
}
Write-Output "Installed scheduler hook. Source SHA256: $currentHash; patched SHA256: $installedHash"
