$webSrc = "client\build\web"
$webDest = "backend\host-daemon\web"

if (-not (Test-Path $webDest)) {
    New-Item -ItemType Directory -Force -Path $webDest | Out-Null
}

Copy-Item -Recurse -Force "$webSrc\*" $webDest
Remove-Item -Force "$webDest\flutter_service_worker.js" -ErrorAction SilentlyContinue

if (Test-Path "$webDest\flutter_bootstrap.js") {
    $b = Get-Content "$webDest\flutter_bootstrap.js" -Raw
    $b = $b -replace 'serviceWorkerSettings:\s*\{[^}]*\}', 'serviceWorkerSettings: null'
    $ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $b = $b.Replace('"mainJsPath":"main.dart.js"', ('"mainJsPath":"main.dart.js?t=' + $ts + '"'))
    Set-Content -Path "$webDest\flutter_bootstrap.js" -Value $b -NoNewline
    Write-Host "Patched flutter_bootstrap.js with timestamp $ts"
}

Write-Host "Web build deployed to backend\host-daemon\web!"
