# Windows 11 Update - Powershell

## This Microsoft Powershell script has one goal - to update Windows 11. Even when the automatic update through the GUI fails.

### All risks associated with this script are on you for running it. See the "What this script does" section for details.
### This script is licensed under GNU GENERAL PUBLIC LICENSE v3, https://www.gnu.org/licenses/gpl-3.0.en.html

#### Author:
https://bsky.app/profile/marcyjcook.bsky.social
Let me know if you run the script, even if you have issues. I may be able to assist, or not.

**Download**
You can download the script from github releases or click the following [link](https://github.com/ravens-wing/Windows-11-Powershell-Update/releases/download/v.1.0/updatew11.ps1
):
https://github.com/ravens-wing/Windows-11-Powershell-Update/releases/download/v.1.0/updatew11.ps1

**How to run the script: Make sure you have powershell installed on Windows 11**
https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5, or 
https://duckduckgo.com/?t=ffab&q=install%20poweshell%20%20%22Windows%2011%22&ia=web

**To Install Powershell to the latest version:**
Winkey > cmd > Run as Administrator
Then type: winget install --id Microsoft.PowerShell --source winget

**To run Powershell:**
Winkey > powershell (select powershell 7 or later) > Run as Administrator
You will be in "PS C:\Windows\System32>", if you downloaded the script to your download folder, type:
cd $HOME\Downloads

**To run the Powershell script:**
You can only run the script like this when you are in the same directory as the script. I recommend doing a reboot before running the script.
Type: ./updateW11.ps1

**Goals:**
Stops services associated with automatic Windows Update.
Deletes the old temporary Windows 11 Update folders.
Updates the core Windows 11 files.
Updates apps from the Microsoft Store.
Updates all installed apps registered inside the OS, which is those that winget has the ability to do.
Starts services associated with automatic Windows Update.

**What this script does:**

This is long winded, but explains what the Powershell script does.

1. Error Handling: Handle-Error Function
```powershell
function Handle-Error {
    param (
        [string]$Message
    )
    Write-Host $Message -ForegroundColor Red
}
```
    Purpose: This function is used to handle and display error messages. It takes a string parameter $Message and outputs it to the console in red to signify an error.
    How it works: Whenever an error occurs in the script, this function is called with the error message to show it in the terminal in a visually distinct color (red).

2. Check and Elevate Privileges: Ensure-ElevatedPrivileges Function
```powershell
function Ensure-ElevatedPrivileges {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Elevating privileges..." -ForegroundColor Yellow
        Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$(${MyInvocation.MyCommand.Path})`"" -Verb RunAs
        exit
    }
}
```
    Purpose: This function checks if the script is being run with administrator privileges.
    How it works:
        It checks the current user’s security principal and verifies if they are part of the "Administrator" role.
        If the script is not elevated, it uses Start-Process to restart the script with administrator privileges (-Verb RunAs), then exits the current script (exit).
        If the script is elevated, it simply continues executing.

3. Service Management: Manage-Services Function
```powershell
function Manage-Services {
    param (
        [string[]]$Services,
        [ValidateSet("Stop", "Start")] [string]$Action
    )
    Write-Host "${Action}ing services..." -ForegroundColor Yellow
    $jobs = @()
    foreach ($service in $Services) {
        $jobs += Start-Job -ScriptBlock {
            param($service, $Action)
            try {
                switch ($Action) {
                    "Stop" { Stop-Service -Name $service -Force -Confirm:$false -ErrorAction Stop }
                    "Start" { Start-Service -Name $service -Confirm:$false -ErrorAction Stop }
                }
                Write-Host "${Action}ed $service." -ForegroundColor Green
            } catch {
                Handle-Error ("Failed to ${Action} service ${service}: $($_.Exception.Message)")
            }
        } -ArgumentList $service, $Action
    }
    $jobs | Wait-Job | Receive-Job
    $jobs | ForEach-Object { Remove-Job -Job $_ }
}
```
    Purpose: This function is used to start or stop Windows services.
    How it works:
        It accepts two parameters: $Services (an array of service names like bits, wuauserv) and $Action (either "Stop" or "Start").
        For each service, it creates a background job that either stops or starts the service, depending on the $Action.
        If the action fails, it uses the Handle-Error function to show the error message.
        It waits for all jobs to finish and then removes them from the job queue.

4. Cleaning Up Incomplete Updates: Clean-Up-IncompleteUpdates Function
```powershell
function Clean-Up-IncompleteUpdates {
    try {
        Write-Host "Cleaning up incomplete Windows updates..." -ForegroundColor Yellow
        Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -Confirm:$false -ErrorAction Stop
        Write-Host "Cleanup complete." -ForegroundColor Green
    } catch {
        Handle-Error ("Failed to clean up incomplete updates: $($_.Exception.Message)")
    }
}
```
    Purpose: This function cleans up any incomplete or leftover Windows Update files from the system.
    How it works:
        It attempts to remove all files in the C:\Windows\SoftwareDistribution\Download\ folder, which is where Windows stores update files.
        If an error occurs during cleanup, it will display an error message via Handle-Error.

5. Updating Progress: Update-Progress Function
```powershell
function Update-Progress {
    param (
        [string]$Activity,
        [int]$PercentComplete
    )
    Write-Progress -Activity $Activity -PercentComplete $PercentComplete
}
```
    Purpose: This function displays a progress bar in the console for long-running operations.
    How it works:
        It takes two parameters: $Activity (a description of the task) and $PercentComplete (a value between 0 and 100 indicating the progress).
        It uses the Write-Progress cmdlet to show the progress bar in the terminal.

6. Ensure PSWindowsUpdate Module is Installed: Ensure-PSWindowsUpdate Function
```powershell
function Ensure-PSWindowsUpdate {
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "PSWindowsUpdate module is not installed. Installing now..." -ForegroundColor Yellow
        Install-Module PSWindowsUpdate -Force -Scope CurrentUser -Confirm:$false
        Import-Module PSWindowsUpdate
        Write-Host "PSWindowsUpdate module installed successfully." -ForegroundColor Green
    } else {
        Import-Module PSWindowsUpdate
    }
}
```
    Purpose: This function checks if the PSWindowsUpdate module is installed. If not, it installs and imports it.
    How it works:
        It checks if PSWindowsUpdate is available using Get-Module.
        If not found, it installs the module using Install-Module and imports it into the current session.

7. Ensure winget is Installed: Ensure-Winget Function
```powershell
function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "winget is not installed. Installing now..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "$(${env:TEMP})\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"
        Add-AppxPackage -Path "$(${env:TEMP})\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle"
        Write-Host "winget installation complete." -ForegroundColor Green
    }
}
```
    Purpose: This function ensures that winget (Windows Package Manager) is installed on the system.
    How it works:
        It checks whether the winget command is available.
        If not, it downloads the installer (Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.appxbundle) from the official link and installs it using Add-AppxPackage.

8. Main Script Execution
```powershell
Write-Host "Starting Script..." -ForegroundColor Yellow
Ensure-ElevatedPrivileges

Manage-Services -Services 'bits', 'wuauserv', 'appidsvc', 'cryptsvc' -Action "Stop"
Clean-Up-IncompleteUpdates
Restart-Service -Name wuauserv -Force
Write-Host "Updating Windows 11..." -ForegroundColor Yellow
```
    Purpose: The script starts by printing a message indicating it's beginning the execution, then it ensures that the script runs with elevated privileges (administrator access).
    How it works:
        It stops Windows Update-related services (bits, wuauserv, appidsvc, cryptsvc) to allow for clean updating.
        It cleans up any incomplete update files and restarts the Windows Update service (wuauserv).

9. Update Windows 11
```powershell
Ensure-PSWindowsUpdate
Update-Progress -Activity "Initializing Update Process" -PercentComplete 0
$updates = Get-WindowsUpdate -AcceptAll
...
```
    Purpose: This section updates Windows 11 by using the PSWindowsUpdate module.
    How it works:
        It first ensures the PSWindowsUpdate module is available.
        Then, it retrieves a list of available updates using Get-WindowsUpdate.
        For each update, it installs the update and displays progress in the console.

10. Update Installed Applications Using Winget
```powershell
Write-Host "Updating installed applications using Winget..." -ForegroundColor Yellow
Ensure-Winget
$installedApps = winget upgrade --all --include-unknown ...
```
    Purpose: This section updates all installed applications using the winget package manager.
    How it works:
        It ensures winget is installed and then uses the winget upgrade --all command to upgrade all installed applications that have available updates.

11. Update Microsoft Store Apps
```powershell
Start-Job -ScriptBlock {
    function Update-Progress { ... }
    try { ... }
}
```
    Purpose: This section updates all Microsoft Store apps by re-registering them.
    How it works:
        A background job is created to update all Microsoft Store apps.
        For each app, it registers it again using Add-AppxPackage to ensure it’s up-to-date.

12. Job Results and Cleanup
```powershell
Get-Job | ForEach-Object { ... }
Write-Host "All updates complete!" -ForegroundColor Green
```
    Purpose: This section checks the results of the background jobs.
    How it works:
        It checks if each job was successful. If any job fails, it logs an error.
        After all tasks are completed, it prints "All updates complete!"

13. Restart Services
```powershell
Manage-Services -Services 'bits', 'wuauserv', 'appidsvc', 'cryptsvc' -Action "Start"
```
    Purpose: Finally, it starts the services that were stopped earlier, such as bits, wuauserv, appidsvc, and cryptsvc.

