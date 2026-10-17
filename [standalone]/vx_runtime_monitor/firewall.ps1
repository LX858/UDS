$ErrorActionPreference = 'Stop'
$ruleName = 'VX Runtime Monitor LAN'
$existing = @(Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)
if ($existing.Count -gt 0) {
    $port = $existing | Get-NetFirewallPortFilter
    $address = $existing | Get-NetFirewallAddressFilter
    if ($existing.Count -ne 1 -or $existing[0].Direction -ne 'Inbound' -or $existing[0].Action -ne 'Allow' -or
        $port.Protocol -ne 'TCP' -or $port.LocalPort -ne '32190' -or
        @($address.LocalAddress) -notcontains '192.168.1.3' -or
        @($address.RemoteAddress) -notcontains '192.168.1.0/24') {
        throw "Existing firewall rule '$ruleName' differs from the expected LAN-only rule."
    }
    Write-Output "Firewall rule already configured: $ruleName"
    exit 0
}

New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Enabled True `
    -Profile Any -Protocol TCP -LocalPort 32190 -LocalAddress '192.168.1.3' `
    -RemoteAddress '192.168.1.0/24' -ErrorAction Stop | Out-Null
if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
    throw "Firewall rule '$ruleName' was not created."
}
Write-Output "Created firewall rule: $ruleName"
