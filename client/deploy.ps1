param([string]$Release = "")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
cd $root
$tmp = "$env:TEMP\lifeos-deploy"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

if (-not $Release) {
    Write-Host "No release specified - building web...`n" -ForegroundColor Yellow
    flutter build web
    if (-not $?) { exit 1 }
    $src = "$root\build\web"
} else {
    $src = (Resolve-Path $Release).Path
}

tar -cf "$tmp\web.tar" -C $src .
if (-not $?) { exit 1 }

cmd /c "tailscale ssh root@pds-laptop-old ""cd /var/lib/lifeos-host-daemon && rm -rf web && mkdir web && tar -xf - -C web"" < $tmp\web.tar"
if (-not $?) { exit 1 }

Remove-Item "$tmp\web.tar"

curl.exe -s -L --max-time 25 -o "$tmp\idx.html" "https://pds-laptop-old.husky-forel.ts.net/" | Out-Null
$public = (Get-FileHash -Algorithm MD5 "$tmp\idx.html").Hash
$local = (Get-FileHash -Algorithm MD5 "$src\index.html").Hash
if ($public -eq $local) { Write-Host "LIVE: new build live sto funnel" -ForegroundColor Green }
else { Write-Host "MISMATCH - check server" -ForegroundColor Red }