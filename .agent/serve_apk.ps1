$vFile = ".\.agent\version.json"
if (-Not (Test-Path $vFile)) { '{"build_number": 0}' | Set-Content $vFile }
$v = Get-Content $vFile | ConvertFrom-Json
$v.build_number++
$v | ConvertTo-Json | Set-Content $vFile
Write-Host "Triggering Build #$($v.build_number)..." -ForegroundColor Cyan

Push-Location "client"
flutter build apk --release --obfuscate --split-debug-info=..\.agent\debug\ --build-number=$($v.build_number)
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed!" -ForegroundColor Red }
Pop-Location

$distDir = ".\backend\host-daemon\dist"
if (-Not (Test-Path $distDir)) { New-Item -ItemType Directory -Force -Path $distDir | Out-Null }
$apkPath = ".\client\build\app\outputs\flutter-apk\app-release.apk"
$destPath = "$distDir\lifeos_latest.apk"
if (Test-Path $apkPath) {
    Copy-Item -Path $apkPath -Destination $destPath -Force -ErrorAction SilentlyContinue
    $v | ConvertTo-Json | Set-Content "$distDir\metadata.json"
}

$port = 8081
$staleProcess = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess
if ($staleProcess) { Stop-Process -Id $staleProcess -Force -ErrorAction SilentlyContinue }

$localIp = (Get-NetIPAddress -InterfaceAlias "Tailscale" -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
if (-not $localIp) { $localIp = "127.0.0.1" }
$url = "http://${localIp}:${port}/lifeos_latest.apk"
$qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=350x350&data=$([uri]::EscapeDataString($url))"
Invoke-RestMethod -Uri $qrUrl -OutFile "$env:TEMP\lifeos_ota_qr.png"
Start-Process "$env:TEMP\lifeos_ota_qr.png"
Write-Host "Target: $url`nPress Ctrl+C to terminate server." -ForegroundColor Green

if (Test-Path $destPath) {
    Push-Location $distDir
    python -m http.server $port
    Pop-Location
} else { Write-Host "Error: APK missing." -ForegroundColor Red }
