# LifeOS host daemon starter (web portal + OAuth + Tailscale Funnel)
# 1) Build once:  go build -o lifeos.exe .
# 2) Put your OAuth credentials in data/oauth.env (copy from data/oauth.env.template)
# 3) Run this script (as the same user that runs the daemon)

# ponytail: control.tailscale.com (AWS range) is blocked on some networks;
# controlplane.tailscale.com (Cloudflare-fronted official endpoint) works everywhere
if (-not $env:CONTROL_URL) { $env:CONTROL_URL = "https://controlplane.tailscale.com" }

$envFile = Join-Path $PSScriptRoot "data\oauth.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^\s*([^#=]+)=(.*)$") {
            [Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim())
        }
    }
}
if (-not $env:OAUTH_BASE_URL) { $env:OAUTH_BASE_URL = "https://lifeos-host.husky-forel.ts.net" }

Start-Process -FilePath (Join-Path $PSScriptRoot "lifeos.exe") -WorkingDirectory $PSScriptRoot -WindowStyle Hidden
Write-Host "LifeOS daemon started (public base: $env:OAUTH_BASE_URL)"
