#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#
# Qlik Sense Database Cleanup Script 1.6
#
#----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Param(
    [string]$QlikSenseInstPath
)

#region Helper functions

    Function Show-Warning($Topic, $Message, [int32]$Type = 0)
    {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        return [System.Windows.Forms.MessageBox]::Show($Message , $Topic, $Type, "Warning")
    }

    Function Show-Info($Topic, $Message, [int32]$Type = 0)
    {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        return [System.Windows.Forms.MessageBox]::Show($Message , $Topic, $Type, "Information")
    }

    Function Show-Error($Topic, $Message, [int32]$Type = 0)
    {
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
        return [System.Windows.Forms.MessageBox]::Show($Message , $Topic, $Type, "Error")
    }
    
    Function Check-PsVersion
    {
        [double]$minReqVersion = 4.0
        if ($PSVersionTable.PsVersion.Major -lt $minReqVersion)
        {
            Write-Warning "You have an old version of PowerShell (V.$($PSVersionTable.PsVersion.Major)). Please update PowerShell to V.$minReqVersion from https://www.microsoft.com/en-us/download/details.aspx?id=40855"
            $result = Show-Warning -Topic "Unsupported version" -Message "You have an old version of PowerShell (V.$($PSVersionTable.PsVersion.Major)). Please update PowerShell to V.$minReqVersion from https://www.microsoft.com/en-us/download/details.aspx?id=40855"
            if ($result -eq "OK")
            {
                Start-Process https://www.microsoft.com/en-us/download/details.aspx?id=40855
            }
            Exit(9999)
        }

    }
    
    
    Function Select-Folder($message='Select folder where Sense is installed (example: C:\Program Files\Qlik\Sense)', $path = 0) 
    { 
        Show-Info -Topic "Important info" -Message "On next dialogue. Select where Qlik Sense is installed and NOT the ProgramData folder" | Out-Null
        
        $object = New-Object -comObject Shell.Application
     
        $folder = $object.BrowseForFolder(0, $message, 1, $path) 
        if ($folder -ne $null) { 
            $folder.self.Path
        }
        else
        {
            Write-Warning "You did not select where Qlik Sense is installed. Using default location ($(FindQlikSenseInstPath))`n"
            <#Read-Host 'Please press ENTER to exit this script' | Out-Null
            Exit(502)#>
        }
    } 
    
    Function VerifyAdminRights
    {
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal( [Security.Principal.WindowsIdentity]::GetCurrent() )
        if ($currentPrincipal.IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator ) -eq $false)
        {
            Clear-Host
            Write-Warning "PowerShell is NOT running as an Administrator. Please start PowerShell as an Administrator and try again`n"
            Show-Warning -Topic "Unsufficient privileges" -Message "PowerShell is NOT running as an Administrator. Please start PowerShell as an Administrator and try again" | Out-Null
            #Read-Host 'Please press ENTER to exit this script' | Out-Null
            Exit(500)
        }
    }
    
    Function FindQlikSenseRepoExe
    {

        $senseinstPath = FindQlikSenseInstPath

        if ((Test-Path $("$senseinstPath")) -eq $false)
        {
            Write-Warning "Could not find Qlik Sense Installed at $senseinstPath - Wrong path when selecting where Sense is installed`n"
            Show-Warning -Topic "Invalid Installation path" -Message "Could not find Qlik Sense Installed at $senseinstPath - Wrong path when selecting where Sense is installed" | Out-Null
            #Read-Host 'Please press ENTER to exit this script' | Out-Null
            Exit(505)
        }

        return $("$senseInstPath\Repository\Repository.exe")
    }
    
    Function FindQlikSenseInstPath
    {
        
        $defaultPath = $("$env:ProgramFiles\Qlik\Sense")
        if ($global:QlikSenseInstPath -eq $null -or $global:QlikSenseInstPath.Length -le 0 -or (Test-Path $("$global:QlikSenseInstPath")) -eq $false)
        {
            $global:QlikSenseInstPath = $defaultPath
        }
        
        return $global:QlikSenseInstPath
    }

    Function FindRepoSenseHomePath
    {
        $senseRepoExeLoc = FindQlikSenseRepoExe
        $senseRepoConfigLoc = $("$senseRepoExeLoc.config")

        if ((Test-Path $("$senseRepoConfigLoc")) -eq $false)
        {
            Show-Warning -Topic "Invalid location" -Message "Could not find Qlik Sense Repository config file at $senseRepoConfigLoc - Wrong path when selecting where Sense is installed`n" | Out-Null
            Write-Warning "Could not find Qlik Sense Repository config file at $senseRepoConfigLoc - Wrong path when selecting where Sense is installed`n"
            #Read-Host 'Please press ENTER to exit this script' | Out-Null
            Exit(501)
        }

        [xml] $xmlReader = Get-Content $senseRepoConfigLoc
        $senseHomeNode = Select-Xml -Xml $xmlReader -XPath "//appSettings/add[@key='SenseHome']"
        
        $repoProgramDataPath = $senseHomeNode.Node.GetAttribute("value")

        if ($repoProgramDataPath -eq $null -or $repoProgramDataPath.Length -lt 1)
		{
            $repoProgramDataPath = $("$env:ProgramData\Qlik\Sense")
        }

        return $repoProgramDataPath
    }

    Function FindSenseLogPath
    {
        $senseHome = FindRepoSenseHomePath

        $senseLogPath = $("$senseHome\Log")
        return $senseLogPath
    }

    Function FindRepositoryProgramDataPath
    {
        $senseHome = FindRepoSenseHomePath
        $repoProgramDataPath = $("$senseHome\Repository")
        
        return $repoProgramDataPath
    }

    Function GetQlikSenseMajorVersion
    {
        $repoPath = FindQlikSenseRepoExe
        $qlikSenseVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($repoPath).FileVersion.Substring(0,3)
        return $qlikSenseVersion
    }

#endregion Helper functions

#region Action functions

    Function StopService([string]$processName)
    {
        $proc = Get-Service -name $processName | where-object { $_.Status -eq "Running" }
        if ($proc.Name -eq $processName)
        {
            $currentComputerName = $(Get-WmiObject Win32_Computersystem).name
            Write-Output $("Stopping $processName")

            Stop-Service -Name $proc.Name -Force | Wait-Process 1200

            Write-Output $("Finished stopping $processName")
            
            $process = Get-Service -Name $processName
            $processStatus = $process.Status
            Write-Output $("Status for $processName is $processStatus")
        }
    }

    Function RunPgScript([string]$scriptFile)
    {
        #Constants
        $compiledScriptFile = "CompiledScript.sql"
        $scriptFile1 = "Recurse_cleanup.sql"
        
        #Get locations
        $qlikSenseInstLoc = FindQlikSenseInstPath
        $qlikSenseProgramDataLoc = FindRepositoryProgramDataPath
        $qlikSenseLogLoc = FindSenseLogPath
        $dateTime = $(Get-Date -format u).Replace(' ', 'T').Replace(':', '_')

        $scriptLoc = $("$PSScriptRoot\$scriptFile")
        $compiledScriptLoc = $("$PSScriptRoot\$compiledScriptFile")
        $scriptFile1Loc = $("$PSScriptRoot\$scriptFile1")

        # Create log folder in case it do not exist
        Write-Host $("Running SQL script")
        if ((Test-Path $("$scriptFile1Loc")) -eq $false)
        {
            Write-Error $("Location to $scriptFile is invalid - location: $scriptFile1Loc")
            Show-Error -Topic "Cannot find SQL script" -Message $("Location to $scriptFile1 is invalid - location: $scriptFile1Loc") | Out-Null
            Exit(520)
        }

        if ((Test-Path $("$scriptLoc")) -eq $true)
        {
            Write-Host $("Building $compiledScriptFile")

            New-Item -ItemType file $compiledScriptLoc -force
            $file1 = Get-Content $scriptFile1Loc
            $file2 = Get-Content $scriptLoc
            Add-Content $compiledScriptLoc $file1
            Add-Content $compiledScriptLoc $file2
        }
        else
        {
            $compiledScriptLoc = $scriptFile1Loc
        }


        if ((Test-Path $("$PSScriptRoot\Logs")) -eq $false)
        {
            New-Item $("$PSScriptRoot\Logs") -ItemType Directory -Force | Out-Null 
        }

        
        Write-Host $("Executing $compiledScriptLoc")

        # Execute SQL script
        $args = @("-U postgres", "-p 4432", "-d QSR", "-e", $("-f `"$compiledScriptLoc`""))
        Start-Process -FilePath $("$qlikSenseInstLoc\Repository\PostgreSQL\9.3\bin\psql.exe") `                        -ArgumentList $args `                        -RedirectStandardError $($PSScriptRoot + "\Logs\\" + $dateTime + "_ErrorLog_SenseCleanupScript.txt") `                        -RedirectStandardOutput $($PSScriptRoot + "\Logs\\" + $dateTime + "_OutputLog_SenseCleanupScript.txt") `
                        -Wait

        Write-Host $("Finished running SQL script`r`n")
    }

    Function DeleteSyncLogs
    {
        $qlikRepoProgramDataLoc = FindRepositoryProgramDataPath

        Write-Host "Removing Sync transaction logs..."
        $snapshotfiles = Get-ChildItem $("$qlikRepoProgramDataLoc\Transaction Logs") |
        Remove-Item -Force
        Write-Host "Finished removing Sync transaction logs `r`n"
    }

    Function ForceSnapshotGen
    {
       $qlikRepoProgramDataLoc = FindRepositoryProgramDataPath

       Write-Host "Enforcing snapshot generation file for startup of Repository service"
       New-Item -Path $("$qlikRepoProgramDataLoc\Transaction Logs\_operation.qrs") -ItemType File -Force | Out-Null
       Write-Host "Finished enforcing snapshot generation file `r`n"
    }

#endregion Action functions

#region Scenario runner

    Clear-Host
    Check-PsVersion
    VerifyAdminRights
    $QlikSenseInstPath = Select-Folder
    $qlikSenseLogLoc = FindSenseLogPath
    $qlikSenseversion = GetQlikSenseMajorVersion
    
    Write-Warning "This script will not startup any Qlik Sense services after finish"
    
    Write-Host $("Make a backup of your environment before proceeeding with this script. See http://help.qlik.com for more information about how to back up your environment") -BackgroundColor Red -ForegroundColor White
    $response = Show-Warning -Topic "Make Qlik Sense Backup" -Type 1 -Message "Make a backup of your environment before proceeeding with this script. See http://help.qlik.com for more information about how to back up your environment`r`nPress OK to proceed"

    if ($response -eq "Cancel")
    {
        Exit(510)
    }
    #Read-Host 'Please press ENTER to continue running this script' | Out-Null

    # Stop all Services
    StopService "QlikSenseRepositoryService"
    StopService "QlikSenseServiceDispatcher"


    # Run Delete script for SoftDeleted items    
    RunPgScript $("CleanupSenseDb_$qlikSenseversion.sql")

    # Delete Snapshot & Transaction log files
    DeleteSyncLogs
     
    # Create _operation.qrs file to enforce snapshot creation
    ForceSnapshotGen

    # Do not start services
    # Remind customer to run this on all machines for Multinode before starting up the services
    Write-Host $("NOTE: Check for errors at $PSScriptRoot\Logs") -ForegroundColor Yellow
    Write-Warning "Run this script on ALL nodes before starting up your Central node Repository Service"
    Show-Info -Topic "Important Info" -Message $("Check for errors at $PSScriptRoot\Logs") | Out-Null
    Show-Info -Topic "Important Info" -Message "Run this script on ALL nodes before starting up your Central node Repository Service" | Out-Null
    #Read-Host 'Please press ENTER to exit this script' | Out-Null

#endregion Scenario runner