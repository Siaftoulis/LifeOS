param (
    [string]$TunnelType = "zrok",
    [string]$TargetPort = "80",
    [string]$ZrokToken = $env:ZROK_TOKEN
)

$Target = "http://localhost:$TargetPort"

if ($TunnelType -eq "zrok") {
    Write-Host "Starting zrok secure tunnel to $Target..." -ForegroundColor Green
    if ($ZrokToken) {
        zrok enable $ZrokToken
    } else {
        Write-Host "Warning: No ZROK_TOKEN provided. Assuming already enabled." -ForegroundColor Yellow
    }
    zrok share public $Target --headless
} elseif ($TunnelType -eq "tailscale") {
    Write-Host "Starting Tailscale Funnel to $Target..." -ForegroundColor Green
    Write-Host "Note: Tailscale Funnel routes public traffic to your local machine via tailnet." -ForegroundColor Cyan
    tailscale funnel --bg=false 443 $Target
} else {
    Write-Host "Unknown tunnel type: $TunnelType. Use 'zrok' or 'tailscale'." -ForegroundColor Red
}
