# PoliMusic IIS Setup Script
# This script must be run as Administrator

$appPath = "C:\Users\User\Desktop\APLICACIONES WEB AVANZADAS\webapppolimusicv1_asp"
$appName = "/webapppolimusicv1_asp"

Write-Host "=== PoliMusic IIS Setup ===" -ForegroundColor Cyan

# Load the WebAdministration module
Import-Module WebAdministration -ErrorAction SilentlyContinue

# Check if the Default Web Site exists
$site = Get-Website -Name "Default Web Site" -ErrorAction SilentlyContinue
if (-not $site) {
    Write-Host "Default Web Site not found. Creating..." -ForegroundColor Yellow
    New-Website -Name "Default Web Site" -Port 80 -PhysicalPath "C:\inetpub\wwwroot" -Force
}

# Create or update the application
$existingApp = Get-WebApplication -Name "Default Web Site" -Application $appName -ErrorAction SilentlyContinue
if ($existingApp) {
    Write-Host "Application already exists. Updating..." -ForegroundColor Yellow
    Set-WebApplication -Name "Default Web Site" -Application $appName -PhysicalPath $appPath
} else {
    Write-Host "Creating IIS application: $appName" -ForegroundColor Green
    New-WebApplication -Site "Default Web Site" -Name "webapppolimusicv1_asp" -PhysicalPath $appPath -ApplicationPool "DefaultAppPool"
}

# Enable ASP for the application
Write-Host "Enabling Classic ASP..." -ForegroundColor Green
Set-WebConfigurationProperty -Filter "/system.webServer/asp" -Name "enable" -Value "true" -Location "Default Web Site/webapppolimusicv1_asp" -ErrorAction SilentlyContinue

# Set folder permissions
Write-Host "Setting folder permissions..." -ForegroundColor Green
& icacls $appPath /grant "IIS_IUSRS:(OI)(CI)RX" /T 2>&1 | Out-Null
& icacls "$appPath\logs" /grant "IIS_IUSRS:(OI)(CI)M" /T 2>&1 | Out-Null

# Restart the app pool
Write-Host "Restarting application pool..." -ForegroundColor Green
Restart-WebAppPool -Name "DefaultAppPool" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Open this URL in your browser:" -ForegroundColor White
Write-Host "  http://localhost/webapppolimusicv1_asp/login.asp" -ForegroundColor Green
Write-Host ""
Write-Host "Test users:" -ForegroundColor White
Write-Host "  userNormal / 12345678  (normal user)" -ForegroundColor Green
Write-Host "  userAdmin  / 12345678  (admin)" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
