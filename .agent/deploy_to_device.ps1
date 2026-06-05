# .agent/deploy_to_device.ps1
# Automates wireless ADB connection, auto-discovers phone IP, uninstalls old app, and installs the latest version.

$ErrorActionPreference = "Continue"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "   LifeOS Automated Wireless Deployer        " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Check if device is already connected via ADB
$devices = adb devices
$connectedDevice = $null

foreach ($line in $devices) {
    if ($line -match "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):5555\s+device") {
        $connectedDevice = $Matches[1]
        Write-Host "Found already connected ADB device: $connectedDevice" -ForegroundColor Green
        break
    }
}

$targetIp = $null
$localIp = (Get-NetIPAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress

if ($connectedDevice) {
    $targetIp = $connectedDevice
} else {
    Write-Host "Searching for device on network..." -ForegroundColor Yellow
    
    # Initialize candidates array
    $candidates = @()
    
    # Candidate 1: Last known local Wi-Fi IP
    $candidates += "192.168.1.7"
    
    # Candidate 2: Check Tailscale status for 'pds-google'
    $tsStatus = tailscale status 2>$null
    if ($tsStatus) {
        foreach ($line in $tsStatus) {
            if ($line -match "(100\.\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+pds-google") {
                $tsIp = $Matches[1]
                Write-Host "Detected Tailscale IP for pds-google: $tsIp" -ForegroundColor Cyan
                if ($candidates -notcontains $tsIp) {
                    $candidates += $tsIp
                }
            }
        }
    }
    
    # Candidate 3: Subnet scan on port 5555
    if ($localIp -and $localIp -match "(\d{1,3}\.\d{1,3}\.\d{1,3})\.\d{1,3}") {
        $subnet = $Matches[1]
        Write-Host "Host Wi-Fi IP is $localIp. Scanning subnet $subnet.0/24..." -ForegroundColor DarkGray
        
        # Scan IPs from .2 to .35
        $scanIps = 2..35
        
        # Test port 5555 in parallel using async TcpClient connection
        $jobs = foreach ($i in $scanIps) {
            $ip = "$subnet.$i"
            [PSCustomObject]@{
                IP = $ip
                Client = [System.Net.Sockets.TcpClient]::new()
            }
        }
        
        # Start connections asynchronously
        foreach ($j in $jobs) {
            try {
                $j.Client.BeginConnect($j.IP, 5555, $null, $null) | Out-Null
            } catch {}
        }
        
        # Wait 300ms for asynchronous connections to complete
        Start-Sleep -Milliseconds 300
        
        foreach ($j in $jobs) {
            if ($j.Client.Connected) {
                Write-Host "Found device listening on port 5555: $($j.IP)" -ForegroundColor Green
                if ($candidates -notcontains $j.IP) {
                    $candidates += $j.IP
                }
            }
            $j.Client.Close()
        }
    }
    
    # Try connecting to candidates
    foreach ($ip in $candidates) {
        if (-not $ip) { continue }
        Write-Host "Attempting to connect to $($ip):5555..." -ForegroundColor DarkGray
        $connectResult = adb connect "$($ip):5555"
        if ($connectResult -match "connected to") {
            Start-Sleep -Seconds 1
            # Verify if it shows up in devices
            $checkDevices = adb devices
            if ($checkDevices -match "$($ip):5555\s+device") {
                Write-Host "Successfully connected to device at $($ip):5555!" -ForegroundColor Green
                $targetIp = $ip
                break
            }
        }
    }
}

if (-not $targetIp) {
    Write-Error "Error: Could not automatically detect or connect to any Android device over Wireless ADB. Please verify that 'Wireless Debugging' is enabled on your phone and that it's on the same Wi-Fi network ($localIp) or Tailscale net."
    exit 1
}

$deviceAddress = "$($targetIp):5555"

# 2. Hard Reset: Uninstalling older version
Write-Host "`n[1/3] Hard resetting the application..." -ForegroundColor Yellow
Write-Host "Uninstalling com.lifeos.app.lifeos_client..." -ForegroundColor DarkGray
$uninstallResult = adb -s $deviceAddress uninstall com.lifeos.app.lifeos_client 2>&1
Write-Host "Uninstall result: $uninstallResult" -ForegroundColor Gray

# 3. Installation of the latest release APK
Write-Host "`n[2/3] Installing the latest compiled release APK..." -ForegroundColor Yellow
$apkPath = "client\build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    Write-Error "Error: Compiled APK not found at $apkPath. Please run serve_apk.ps1 first!"
    exit 1
}
Write-Host "Installing $apkPath..." -ForegroundColor DarkGray
$installResult = adb -s $deviceAddress install -r $apkPath 2>&1
Write-Host "Install result: $installResult" -ForegroundColor Gray

if ($installResult -match "Success") {
    Write-Host "`n[3/3] Launching LifeOS on the device..." -ForegroundColor Yellow
    $launchResult = adb -s $deviceAddress shell monkey -p com.lifeos.app.lifeos_client -c android.intent.category.LAUNCHER 1 2>&1
    Write-Host "Launch triggered." -ForegroundColor Green
    
    Write-Host "`n=============================================" -ForegroundColor Green
    Write-Host "   Deployment successfully completed! 🎉    " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
} else {
    Write-Error "Error: App installation failed!"
    exit 1
}
