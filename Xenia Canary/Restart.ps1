# Get the directory where the script is located
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define the paths to the Playnite executables (relative to the script directory)
$desktopAppPath = Join-Path $scriptDirectory "Playnite.DesktopApp.exe"
$fullscreenAppPath = Join-Path $scriptDirectory "Playnite.FullscreenApp.exe"

# Check if Playnite.DesktopApp.exe is running
if (Get-Process -Name "Playnite.DesktopApp" -ErrorAction SilentlyContinue) {
    Write-Host "Playnite.DesktopApp.exe is running. Stopping and restarting..."
    Stop-Process -Name "Playnite.DesktopApp" -Force
    Start-Process -FilePath $desktopAppPath
} else {
    # Check if Playnite.FullscreenApp.exe is running
    if (Get-Process -Name "Playnite.FullscreenApp" -ErrorAction SilentlyContinue) {
        Write-Host "Playnite.FullscreenApp.exe is running. Stopping and restarting..."
        Stop-Process -Name "Playnite.FullscreenApp" -Force
        Start-Process -FilePath $fullscreenAppPath
    } else {
        Write-Host "Neither Playnite.DesktopApp.exe nor Playnite.FullscreenApp.exe is running."
    }
}
