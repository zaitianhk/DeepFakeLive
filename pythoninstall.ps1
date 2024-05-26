param (
    [string]$PythonVersion = "3.10.11",
    [string]$PythonInstaller = "python-3.10.11-amd64.exe",
    [string]$PythonInstallerUrl = "https://www.python.org/ftp/python/$PythonVersion/$PythonInstaller",
    [string]$PythonInstallDir = "C:\Python$PythonVersion",
    [string]$PythonUninstallKey32 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
    [string]$PythonUninstallKey64 = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

# Log file path
$logFile = "C:\path\to\your\script\install_log.txt"

# Function to write to log
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
    Write-Host $message
}

function Uninstall-Python {
    param (
        [string]$UninstallKey
    )

    try {
        $pythonKeys = Get-ItemProperty -Path $UninstallKey\* | Where-Object { $_.DisplayName -like "Python*" }
        foreach ($key in $pythonKeys) {
            if ($key.UninstallString) {
                Write-Log "Uninstalling $($key.DisplayName)..."
                $uninstallString = $key.UninstallString -replace '/I', '/X'  # Change '/I' to '/X' to force uninstall
                Start-Process "cmd.exe" -ArgumentList "/c $uninstallString /quiet /norestart" -Wait
                Write-Log "$($key.DisplayName) uninstalled."
            } else {
                Write-Log "Uninstall string not found for $($key.DisplayName). Skipping..."
            }
        }
    } catch {
        Write-Log "An error occurred while attempting to uninstall Python versions: $_"
    }
}

Write-Log "Uninstalling 32-bit Python versions..."
Uninstall-Python -UninstallKey $PythonUninstallKey32

Write-Log "Uninstalling 64-bit Python versions..."
Uninstall-Python -UninstallKey $PythonUninstallKey64

# Download Python installer
Write-Log "Downloading Python $PythonVersion installer from $PythonInstallerUrl..."
try {
    Invoke-WebRequest -Uri $PythonInstallerUrl -OutFile $PythonInstaller
    Write-Log "Download completed."
} catch {
    Write-Log "Error downloading Python installer: $_"
    exit
}

# Verify if the download was successful
if (-Not (Test-Path -Path $PythonInstaller)) {
    Write-Log "Error: Downloading Python installer failed."
    exit
}

# Install Python
Write-Log "Installing Python $PythonVersion..."
try {
    Start-Process -FilePath $PythonInstaller -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1" -Wait
    if ($LastExitCode -ne 0) {
        Write-Log "Error: Python installation failed with exit code $LastExitCode."
        exit
    }
    Write-Log "Python $PythonVersion installed."
} catch {
    Write-Log "Error: Python installation failed: $_"
    exit
}

# Verify the installation and set the environment variable
$pythonPath = Join-Path -Path $PythonInstallDir -ChildPath "Scripts"
if (Test-Path $pythonPath) {
    [Environment]::SetEnvironmentVariable("Path", "$($env:Path);$pythonPath", "Machine")
    Write-Log "Python executable path added to system environment variables."
} else {
    Write-Log "Error: Python installation directory not found."
}

Write-Log "Script completed."
