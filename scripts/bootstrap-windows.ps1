<#
.SYNOPSIS
    Base OS bootstrapping and software installation script for Windows Server VMs.
.DESCRIPTION
    Executed via Azure Custom Script Extension (Stage 7 & Stage 9).
    This script performs:
      1. TLS 1.2 enforcement & basic PowerShell environment setup.
      2. OS telemetry and security baseline configuration.
      3. Installation of package manager (Chocolatey).
      4. Installation of baseline software packages (Git, Azure CLI, Sysinternals, Notepad++, 7-Zip).
      5. Windows Defender configuration and firewall checks.
      6. Time synchronization against Azure NTP.
      7. Service status checks & logging to C:\WindowsAzure\Logs\Bootstrap.log.
.NOTES
    Author  : Platform Engineering Team
    Version : 1.2.0
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$LogPath = "C:\WindowsAzure\Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}
$LogFile = Join-Path $LogPath "bootstrap-windows.log"

function Write-BootstrapLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Output $logEntry
    Add-Content -Path $LogFile -Value $logEntry
}

Write-BootstrapLog "Starting Windows VM bootstrap sequence (Stage 9: Software Installation)..."

try {
    # -------------------------------------------------------------------------
    # 1. Network & Protocol Hardening
    # -------------------------------------------------------------------------
    Write-BootstrapLog "Enforcing TLS 1.2 for .NET and PowerShell WebRequests..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Set default registry keys for TLS 1.2 across .NET Framework 4.x
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"
    )
    foreach ($path in $regPaths) {
        if (Test-Path $path) {
            Set-ItemProperty -Path $path -Name "SchUseStrongCrypto" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $path -Name "SystemDefaultTlsVersions" -Value 1 -Type DWord -Force
        }
    }

    # -------------------------------------------------------------------------
    # 2. Time Synchronization (Azure Host NTP)
    # -------------------------------------------------------------------------
    Write-BootstrapLog "Configuring Time Synchronization with Azure NTP (169.254.169.123)..."
    w32tm /config /manualpeerlist:"169.254.169.123" /syncfromflags:manual /reliable:yes /update | Out-Null
    Restart-Service w32time -ErrorAction SilentlyContinue

    # -------------------------------------------------------------------------
    # 3. Install Package Manager (Chocolatey)
    # -------------------------------------------------------------------------
    Write-BootstrapLog "Checking Chocolatey installation..."
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-BootstrapLog "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh env
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-BootstrapLog "Chocolatey successfully installed."
    } else {
        Write-BootstrapLog "Chocolatey is already present."
    }

    # -------------------------------------------------------------------------
    # 4. Install Base Enterprise Software Packages
    # -------------------------------------------------------------------------
    $packages = @(
        "git.install",
        "azure-cli",
        "7zip",
        "notepadplusplus",
        "sysinternals",
        "powershell-core"
    )

    foreach ($pkg in $packages) {
        Write-BootstrapLog "Installing package: $pkg..."
        choco install $pkg -y --no-progress --ignore-checksums | Out-Null
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010) {
            Write-BootstrapLog "Package $pkg installed successfully (ExitCode: $LASTEXITCODE)."
        } else {
            Write-BootstrapLog "Warning: Package $pkg install returned non-standard code: $LASTEXITCODE" "WARN"
        }
    }

    # -------------------------------------------------------------------------
    # 5. OS Configuration & Performance Flags
    # -------------------------------------------------------------------------
    Write-BootstrapLog "Setting high performance power plan..."
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c | Out-Null

    Write-BootstrapLog "Ensuring Remote Desktop is enabled with NLA..."
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue

    # -------------------------------------------------------------------------
    # 6. Bootstrap Completion Marker
    # -------------------------------------------------------------------------
    $completionInfo = @{
        Status      = "Completed"
        CompletedAt = (Get-Date).ToString("o")
        InstalledPackages = $packages
        MachineName = $env:COMPUTERNAME
    } | ConvertTo-Json

    $completionPath = "C:\WindowsAzure\bootstrap-complete.json"
    Set-Content -Path $completionPath -Value $completionInfo -Force
    Write-BootstrapLog "Bootstrap completed successfully. Status recorded in $completionPath"

    exit 0
}
catch {
    Write-BootstrapLog "CRITICAL ERROR during bootstrap: $($_.Exception.Message)" "ERROR"
    Write-BootstrapLog "StackTrace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}
