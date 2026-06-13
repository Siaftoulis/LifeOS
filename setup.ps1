# Setup Script for LifeOS Monorepo Development Environment

Write-Host "=========================================" -ForegroundColor Green
Write-Host "        LifeOS Setup Bootstrapper        " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

function Check-Command ($cmd) {
    return [bool](Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Install-Tool ($name, $id) {
    Write-Host "$name is not installed. Attempting to install via winget..." -ForegroundColor Yellow
    winget install $id --silent --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$name installed successfully! Please restart this terminal/IDE to update PATH variables." -ForegroundColor Green
    } else {
        Write-Host "Failed to install $name. Please install it manually." -ForegroundColor Red
    }
}

# Check Git
if (-not (Check-Command "git")) {
    Install-Tool "Git" "Git.Git"
} else {
    Write-Host "[OK] Git is already installed." -ForegroundColor Green
}

# Check Go
if (-not (Check-Command "go")) {
    Install-Tool "Go Language" "GoLang.Go"
} else {
    Write-Host "[OK] Go is already installed." -ForegroundColor Green
}

# Check Flutter
if (-not (Check-Command "flutter")) {
    Install-Tool "Flutter SDK" "Flutter.Flutter"
} else {
    Write-Host "[OK] Flutter is already installed." -ForegroundColor Green
}

Write-Host ""
Write-Host "-----------------------------------------" -ForegroundColor Gray
Write-Host "Installing project dependencies..." -ForegroundColor Green
Write-Host "-----------------------------------------" -ForegroundColor Gray
Write-Host ""

# Flutter dependencies
if (Test-Path "client") {
    Write-Host "--> Running 'flutter pub get' in client directory..." -ForegroundColor Cyan
    Push-Location client
    flutter pub get
    Pop-Location
}

# Go backend dependencies
if (Test-Path "backend/host-daemon") {
    Write-Host "--> Running 'go mod download' in backend/host-daemon directory..." -ForegroundColor Cyan
    Push-Location backend/host-daemon
    go mod download
    Pop-Location
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "         Setup Process Completed!        " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "IMPORTANT: If any compiler tools or SDKs were newly installed, please RESTART your terminal/IDE to apply new PATH environment variables." -ForegroundColor Yellow
Write-Host ""
