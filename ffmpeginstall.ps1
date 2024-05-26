param (
    [string]$FFMPEGVersion = "4.3.1",
    [string]$FFMPEGUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-full.7z",
    [string]$FFMPEGInstallDir = "C:\ffmpeg"
)

# Log file path
$logFile = "$PSScriptRoot\install_log.txt"

# Function to write to log
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
    Write-Host $message
}

# Download FFmpeg
Write-Log "Downloading FFmpeg version $FFMPEGVersion from $FFMPEGUrl..."
try {
    Invoke-WebRequest -Uri $FFMPEGUrl -OutFile "$PSScriptRoot\ffmpeg-release-full.7z"
    Write-Log "Download completed."
} catch {
    Write-Log "Error downloading FFmpeg: $_"
    exit
}

# Extract the 7z file
Write-Log "Extracting FFmpeg..."
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $sevenZipPath = "C:\Program Files\7-Zip\7z.exe"  # Path to 7z executable
    $extractPath = $PSScriptRoot
    Start-Process -FilePath $sevenZipPath -ArgumentList "x", "`"$PSScriptRoot\ffmpeg-release-full.7z`"", "-o`"$extractPath`"", "-y" -Wait
    Write-Log "Extraction completed."
} catch {
    Write-Log "Error extracting FFmpeg: $_"
    exit
}

# Move FFmpeg binaries to the installation directory
Write-Log "Installing FFmpeg..."
try {
    if (-Not (Test-Path -Path $FFMPEGInstallDir)) {
        New-Item -ItemType Directory -Path $FFMPEGInstallDir
    }
    Move-Item -Path "$PSScriptRoot\ffmpeg-release-full\bin\*" -Destination $FFMPEGInstallDir -Force
    Write-Log "FFMPEG binaries moved to $FFMPEGInstallDir."
} catch {
    Write-Log "Error installing FFmpeg: $_"
    exit
}

# Clean up
Write-Log "Cleaning up..."
try {
    Remove-Item -Path "$PSScriptRoot\ffmpeg-release-full*" -Recurse -Force
    Write-Log "Cleanup completed."
} catch {
    Write-Log "Error cleaning up: $_"
}

# Add FFmpeg to the PATH environment variable
Write-Log "Adding FFmpeg to PATH..."
try {
    $currentPath = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine)
    if (-not $currentPath.Contains($FFMPEGInstallDir)) {
        [System.Environment]::SetEnvironmentVariable("Path", "$currentPath;$FFMPEGInstallDir", [System.EnvironmentVariableTarget]::Machine)
        Write-Log "FFmpeg installation directory added to PATH."
    } else {
        Write-Log "FFmpeg installation directory is already in PATH."
    }
} catch {
    Write-Log "Error adding FFmpeg to PATH: $_"
    exit
}

# Verify installation
Write-Log "Verifying FFmpeg installation..."
try {
    & "$FFMPEGInstallDir\ffmpeg.exe" -version
    if ($?) {
        Write-Log "FFmpeg installed and verified successfully."
    } else {
        Write-Log "Error: FFmpeg verification failed."
    }
} catch {
    Write-Log "Error: FFmpeg executable not found or not working correctly: $_"
    exit
}

Write-Log "Script completed successfully."
