Write-Host "Triggering Flutter Profile Build..." -ForegroundColor Cyan
Set-Location -Path "client"
flutter build apk --profile
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed. Proceeding with existing binary if available." -ForegroundColor Yellow
}
Set-Location -Path ".."

# Dynamically resolve active local LAN IP
$localIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -match "^192\." -or $_.IPAddress -match "^10\." -or $_.IPAddress -match "^172\." } | Select-Object -ExpandProperty IPAddress -First 1)
$port = 8081
$apkPath = "client/build/app/outputs/flutter-apk"
$downloadUrl = "http://${localIp}:${port}/app-profile.apk"

Write-Host "`nTarget Download URL: $downloadUrl" -ForegroundColor Green
Write-Host "Scan the QR Code below to install:`n" -ForegroundColor Cyan

# Zero-dependency terminal ASCII QR Code generation via free API
curl.exe -s "https://qrenco.de/${downloadUrl}"

Write-Host "`nPress Ctrl+C to terminate the ephemeral server." -ForegroundColor Red

if (Test-Path -Path $apkPath) {
    Push-Location $apkPath
    python -m http.server $port
    Pop-Location
} else {
    Write-Host "Error: APK path missing. Ensure Flutter compiled correctly." -ForegroundColor Red
}
