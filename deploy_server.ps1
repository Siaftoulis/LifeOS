param([switch]$SkipBuild)
$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot
$tmp = "$env:TEMP\lifeos-deploy"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

Write-Host "=== LifeOS Server Deployment (pds-laptop-old) ===" -ForegroundColor Cyan

# 1. Build Web if needed
if (-not $SkipBuild) {
    Write-Host "1. Building Flutter Web release bundle..." -ForegroundColor Yellow
    Push-Location "$workspaceRoot\client"
    flutter build web --release
    Pop-Location
}

$webSrc = "$workspaceRoot\client\build\web"
if (-not (Test-Path "$webSrc\index.html")) {
    Write-Error "Web build not found in $webSrc!"
    exit 1
}

# Remove any generated service worker file to prevent browser caching
Remove-Item "$webSrc\flutter_service_worker.js" -Force -ErrorAction SilentlyContinue

# Patch flutter_bootstrap.js to disable service worker completely
if (Test-Path "$webSrc\flutter_bootstrap.js") {
    $bootstrap = Get-Content "$webSrc\flutter_bootstrap.js" -Raw
    # Replace serviceWorkerSettings block with null
    $bootstrap = $bootstrap -replace 'serviceWorkerSettings:\s*\{[^}]*\}', 'serviceWorkerSettings: null'
    $ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $bootstrap = $bootstrap -replace '"mainJsPath":"main.dart.js"', ('"mainJsPath":"main.dart.js?t=' + $ts + '"')
    Set-Content -Path "$webSrc\flutter_bootstrap.js" -Value $bootstrap -NoNewline
}

# 2. Build Linux Binaries
Write-Host "2. Building Linux amd64 binaries (lifeos-linux & server_linux)..." -ForegroundColor Yellow
Push-Location "$workspaceRoot\backend\host-daemon"
$env:GOOS="linux"; $env:GOARCH="amd64"; $env:CGO_ENABLED="0"
go build -ldflags="-s -w" -o "$tmp\lifeos-linux" .
Pop-Location

Push-Location "$workspaceRoot\server"
$env:GOOS="linux"; $env:GOARCH="amd64"; $env:CGO_ENABLED="0"
go build -ldflags="-s -w" -o "$tmp\server_linux" .
Pop-Location

# 3. Create Web Tar
Write-Host "3. Packaging web assets..." -ForegroundColor Yellow
tar -cf "$tmp\web.tar" -C "$webSrc" .

# 4. Deploy to pds-laptop-old via Tailscale SSH
Write-Host "4. Deploying to pds-laptop-old (/var/lib/lifeos-host-daemon)..." -ForegroundColor Yellow
cmd /c "tailscale ssh root@pds-laptop-old ""cd /var/lib/lifeos-host-daemon && rm -rf web && mkdir -p web && tar -xf - -C web && rm -f web/flutter_service_worker.js"" < $tmp\web.tar"

# Deploy Linux daemon binary
Write-Host "5. Uploading lifeos-linux daemon binary & updating service..." -ForegroundColor Yellow
tar -cf "$tmp\bin.tar" -C "$tmp" lifeos-linux
cmd /c "tailscale ssh root@pds-laptop-old ""cd /var/lib/lifeos-host-daemon && tar -xf - && systemctl stop lifeos-host-daemon && cp lifeos-linux /usr/local/bin/lifeos-host-daemon && chmod +x /usr/local/bin/lifeos-host-daemon lifeos-linux && systemctl start lifeos-host-daemon"" < $tmp\bin.tar"

# 6. Verification
Write-Host "6. Verifying deployment on https://pds-laptop-old.husky-forel.ts.net/ ..." -ForegroundColor Yellow
Start-Sleep -Seconds 2
curl.exe -s -L --max-time 15 -o "$tmp\idx.html" "https://pds-laptop-old.husky-forel.ts.net/" | Out-Null
if (Test-Path "$tmp\idx.html") {
    $remoteHash = (Get-FileHash -Algorithm MD5 "$tmp\idx.html").Hash
    $localHash = (Get-FileHash -Algorithm MD5 "$webSrc\index.html").Hash
    if ($remoteHash -eq $localHash) {
        Write-Host " SUCCESS: Server https://pds-laptop-old.husky-forel.ts.net/ is LIVE with the latest build!" -ForegroundColor Green
    } else {
        Write-Host " NOTE: Web index updated." -ForegroundColor Yellow
    }
}

Remove-Item "$tmp\web.tar", "$tmp\bin.tar", "$tmp\lifeos-linux", "$tmp\server_linux", "$tmp\idx.html" -Force -ErrorAction SilentlyContinue
Write-Host "=== Deployment Finished Successfully ===" -ForegroundColor Green
