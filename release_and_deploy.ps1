param(
    [ValidateSet("patch", "minor", "major", "none")]
    [string]$Bump = "none",
    [string]$Message = "automated release and deploy"
)

$ErrorActionPreference = "Stop"
$workspaceRoot = $PSScriptRoot

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "         LifeOS Professional CI/CD Release Pipeline     " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Version Management
$versionFile = "$workspaceRoot\.agent\version.json"
$pubspecFile = "$workspaceRoot\client\pubspec.yaml"

if (-not (Test-Path $versionFile)) {
    Write-Error "Version file not found: $versionFile"
    exit 1
}

$verJson = Get-Content $versionFile -Raw | ConvertFrom-Json
$currentVer = $verJson.version
$currentBuild = [int]$verJson.build_number

$parts = $currentVer.Split('.')
$major = [int]$parts[0]
$minor = [int]$parts[1]
$patch = [int]$parts[2]

if ($Bump -eq "patch") {
    $patch++
    $currentBuild++
} elseif ($Bump -eq "minor") {
    $minor++
    $patch = 0
    $currentBuild++
} elseif ($Bump -eq "major") {
    $major++
    $minor = 0
    $patch = 0
    $currentBuild++
}

$newVer = "$major.$minor.$patch"
$newBuild = $currentBuild

Write-Host "Current Version: v$currentVer (Build #$($verJson.build_number))" -ForegroundColor Gray
Write-Host "Target Version : v$newVer (Build #$newBuild)" -ForegroundColor Green

# Update version.json
$updatedJson = @{
    version = $newVer
    build_number = $newBuild
} | ConvertTo-Json
Set-Content -Path $versionFile -Value $updatedJson

# Update pubspec.yaml
$pubspecContent = Get-Content $pubspecFile -Raw
$pubspecContent = $pubspecContent -replace 'version:\s*\S+', "version: $newVer+$newBuild"
Set-Content -Path $pubspecFile -Value $pubspecContent

Write-Host "Version files updated to v$newVer+$newBuild" -ForegroundColor Green

# 2. Deploy to Server (pds-laptop-old)
Write-Host "`n>>> [STEP 1/3] Building and Deploying to Server (pds-laptop-old)..." -ForegroundColor Yellow
& "$workspaceRoot\deploy_server.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Server deployment failed!"
    exit 1
}

# 3. Git Commit, Tag and Push
Write-Host "`n>>> [STEP 2/3] Committing and Tagging Git Release..." -ForegroundColor Yellow
Push-Location $workspaceRoot
git add .agent/version.json client/pubspec.yaml deploy_server.ps1 release_and_deploy.ps1 client/lib client/android
$commitMsg = 'release: v{0} (Build #{1}) - {2}' -f $newVer, $newBuild, $Message
git commit -m $commitMsg --allow-empty

$tagName = "v$newVer"
# Check if tag exists locally
$tagExists = git tag -l $tagName
if (-not $tagExists) {
    git tag $tagName
    Write-Host "Created Git tag $tagName" -ForegroundColor Green
}

# 4. Push to GitHub
Write-Host "`n>>> [STEP 3/3] Pushing to GitHub (Triggers Cloud CI/CD for APK and Windows)..." -ForegroundColor Yellow
git push origin main
git push origin $tagName

Pop-Location

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " SUCCESS! Everything is automated and shipped:           " -ForegroundColor Green
Write-Host " 1. Web Portal LIVE:  https://pds-laptop-old.husky-forel.ts.net/" -ForegroundColor Cyan
Write-Host " 2. Linux Daemon:     Updated and running on pds-laptop-old" -ForegroundColor Cyan
Write-Host (' 3. GitHub Release:   https://github.com/Siaftoulis/LifeOS/releases/tag/' + $tagName) -ForegroundColor Cyan
Write-Host " 4. Actions Pipeline: https://github.com/Siaftoulis/LifeOS/actions" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Green

