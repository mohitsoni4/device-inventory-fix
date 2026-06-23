# Ensure script is running as Administrator
$adminCheck = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $adminCheck) {
    Write-Output "Script must be run as Administrator."
    exit 1
}

Write-Output "Starting Office inventory remediation..."

# Registry paths to delete
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Office\C2RSvcMgr",
    "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\AutoProvisioning",
    "HKCU:\SOFTWARE\Microsoft\Office\16.0\Common\Identity"
)

foreach ($path in $regPaths) {
    try {
        if (Test-Path $path) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Write-Output "Deleted: $path"
        } else {
            Write-Output "Path not found: $path"
        }
    } catch {
        Write-Output "Failed to delete ${path}: $_"
    }
}

# Office Service Manager path
$svcMgrPath = "C:\Program Files\Common Files\Microsoft Shared\ClickToRun\officesvcmgr.exe"

if (Test-Path $svcMgrPath) {
    try {
        Write-Output "Running inventory check-in..."
        Start-Process -FilePath $svcMgrPath -ArgumentList "/checkin" -Wait -NoNewWindow -ErrorAction Stop
        
        Write-Output "Sending inventory..."
        Start-Process -FilePath $svcMgrPath -ArgumentList "/sendinventory" -Wait -NoNewWindow -ErrorAction Stop
        
        Write-Output "Inventory sync completed successfully."
    }
    catch {
        Write-Output "Failed to execute officesvcmgr.exe commands: $_"
    }
} else {
    Write-Output "officesvcmgr.exe not found at expected path."
    Exit 1
}

Write-Output "Script completed."