# .agent/deploy_to_device.ps1
# Automates wireless ADB connection, auto-discovers phone IP and dynamic wireless debugging port,
# uninstalls the old app version, and installs the latest version.

$ErrorActionPreference = "Continue"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "      LifeOS Automated Wireless Deployer     " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Determine the best ADB executable to use
$adb = "adb"
$preferredAdbPaths = @(
    "C:\Users\PDS_Dev\0_Environment\Apps\scoop\apps\android-clt\current\platform-tools\adb.exe",
    "$env:USERPROFILE\0_Environment\Apps\scoop\apps\android-clt\current\platform-tools\adb.exe",
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
)

foreach ($path in $preferredAdbPaths) {
    if (Test-Path $path) {
        $adb = $path
        Write-Host "Using preferred ADB path: $adb" -ForegroundColor Gray
        break
    }
}

# 2. Check if device is already connected via ADB
$devices = & $adb devices
$connectedDeviceAddress = $null

foreach ($line in $devices) {
    if ($line -match "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):(\d+)\s+device") {
        $connectedDeviceAddress = $Matches[0]
        Write-Host "Found already connected ADB device: $connectedDeviceAddress" -ForegroundColor Green
        break
    }
}

$targetAddress = $null

if ($connectedDeviceAddress) {
    $targetAddress = $connectedDeviceAddress
} else {
    Write-Host "Searching for device on network..." -ForegroundColor Yellow
    
    $ipCandidates = @("192.168.1.7")
    $localIp = (Get-NetIPAddress -InterfaceAlias "Wi-Fi" -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    
    # Dynamically discover local subnet candidate IPs from ARP table
    if ($localIp -and $localIp -match "^(\d{1,3}\.\d{1,3}\.\d{1,3}\.)") {
        $prefix = $Matches[1]
        $escapedPrefix = [regex]::Escape($prefix)
        $arpLines = arp -a 2>$null
        if ($arpLines) {
            foreach ($line in $arpLines) {
                if ($line -match "($escapedPrefix\d+)\s+[a-f0-9-]{17}\s+dynamic") {
                    $candidate = $Matches[1]
                    # Exclude obvious non-device IPs like .1 (gateway) or .255 (broadcast)
                    if ($candidate -ne "$($prefix)1" -and $candidate -ne "$($prefix)255" -and $ipCandidates -notcontains $candidate) {
                        $ipCandidates += $candidate
                    }
                }
            }
        }
    }
    
    # Try Tailscale IP candidate
    $tsStatus = tailscale status 2>$null
    if ($tsStatus) {
        foreach ($line in $tsStatus) {
            if ($line -match "(100\.\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+pds-google") {
                $tsIp = $Matches[1]
                Write-Host "Detected Tailscale IP for pds-google: $tsIp" -ForegroundColor Cyan
                if ($ipCandidates -notcontains $tsIp) {
                    $ipCandidates += $tsIp
                }
            }
        }
    }
    
    # Dynamically scan dynamic wireless debugging ports (typically 35000-45000) on candidates
    $foundPort = $null
    $foundIp = $null
    
    foreach ($ip in $ipCandidates) {
        Write-Host "Scanning $ip for active Wireless Debugging ports (35000-45000)..." -ForegroundColor DarkGray
        if (-not (Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue)) {
            Write-Host "Host $ip is not reachable (ping failed). Skipping." -ForegroundColor DarkGray
            continue
        }
        
        # Scan in chunks of 500
        $ports = 35000..45000
        $timeout = 250 # ms
        $chunkSize = 500
        
        for ($i = 0; $i -lt $ports.Count; $i += $chunkSize) {
            $chunk = $ports[$i..($i + $chunkSize - 1)]
            $tasks = @()
            foreach ($port in $chunk) {
                if ($port -eq $null) { continue }
                $client = New-Object System.Net.Sockets.TcpClient
                try {
                    $ar = $client.BeginConnect($ip, $port, $null, $null)
                    $tasks += [PSCustomObject]@{
                        Port = $port
                        Client = $client
                        AsyncResult = $ar
                    }
                } catch {
                    $client.Close()
                }
            }
            
            [System.Threading.Thread]::Sleep($timeout)
            
            foreach ($t in $tasks) {
                if ($t.AsyncResult.IsCompleted) {
                    try {
                        $t.Client.EndConnect($t.AsyncResult)
                        if ($t.Client.Connected) {
                            $foundPort = $t.Port
                            $foundIp = $ip
                            Write-Host "Found active Wireless Debugging port: $foundPort on $foundIp" -ForegroundColor Green
                        }
                    } catch {}
                }
                $t.Client.Close()
                if ($foundPort) { break }
            }
            if ($foundPort) { break }
        }
        if ($foundPort) { break }
    }
    
    if ($foundIp -and $foundPort) {
        $attemptAddress = "$($foundIp):$foundPort"
        Write-Host "Attempting to connect to $attemptAddress..." -ForegroundColor DarkGray
        $connectResult = & $adb connect $attemptAddress
        if ($connectResult -match "connected to") {
            Start-Sleep -Seconds 1
            $checkDevices = & $adb devices
            if ($checkDevices -match "$($foundIp):$($foundPort)\s+device") {
                Write-Host "Successfully connected to device at $attemptAddress!" -ForegroundColor Green
                $targetAddress = $attemptAddress
            }
        }
    }
}

if (-not $targetAddress) {
    Write-Error "Error: Could not automatically detect or connect to any Android device over Wireless ADB. Please verify that 'Wireless Debugging' is enabled on your phone and that it's on the same Wi-Fi network or Tailscale net."
    exit 1
}

# 3. Hard Reset: Uninstalling older version
Write-Host "`n[1/3] Hard resetting the application..." -ForegroundColor Yellow
Write-Host "Uninstalling com.lifeos.app.lifeos_client..." -ForegroundColor DarkGray
$uninstallResult = & $adb -s $targetAddress uninstall com.lifeos.app.lifeos_client 2>&1
Write-Host "Uninstall result: $uninstallResult" -ForegroundColor Gray

# 4. Installation of the latest release APK
Write-Host "`n[2/3] Installing the latest compiled release APK..." -ForegroundColor Yellow
$apkPath = "client\build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
    Write-Error "Error: Compiled APK not found at $apkPath."
    exit 1
}
Write-Host "Installing $apkPath..." -ForegroundColor DarkGray
$installResult = & $adb -s $targetAddress install -r $apkPath 2>&1
Write-Host "Install result: $installResult" -ForegroundColor Gray

if ($installResult -match "Success") {
    Write-Host "`n[3/3] Launching LifeOS on the device..." -ForegroundColor Yellow
    $null = & $adb -s $targetAddress shell monkey -p com.lifeos.app.lifeos_client -c android.intent.category.LAUNCHER 1 2>&1
    Write-Host "Launch triggered." -ForegroundColor Green
    
    Write-Host "`n=============================================" -ForegroundColor Green
    Write-Host "         Deployment successfully completed!  " -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
} else {
    Write-Error "Error: App installation failed!"
    exit 1
}
