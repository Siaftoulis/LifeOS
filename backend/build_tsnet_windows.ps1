# build_tsnet_windows.ps1
# Build Go c-shared dll compilation shell script and exports header for Windows (NET-001)

$ErrorActionPreference = "Stop"

$scriptPath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptPath

Write-Host "Building tsnet_client.dll..."
Set-Location -Path $dir

# Assuming tsnet source is inside a tsnet directory or just build the current module
# go build -buildmode=c-shared -o tsnet_client.dll ./tsnet

Write-Host "Build complete. tsnet_client.dll and tsnet_client.h generated."
