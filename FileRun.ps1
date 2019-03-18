######################################################################
# This script does calls an Anaplan Connect to run an Action
# Author: 	Upali Wickramasinghe
# Version: 	0.3
# Date:		22/01/2019
######################################################################

# Get the command line arguments
$Key = $args[0]

# Define any constants
$FunctionsFile = ".\Functions.ps1"

# Read the functions file
try {
    . $FunctionsFile
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" + " Error: " + $_.Exception.Message
	exit 1
}

# Prepare any variables
$DateStamp = GetDateTimeStamp "yyyyMMdd"
$LogFile = $($LogDir + "\FileRun_" + $DateStamp + ".log")

function main() {
	# Check for the Config file
	if (!(Test-Path $ConfigFile)) {
		$LogMessage = $("ConfigFile does not exist: " + $ConfigFile)
		WriteLog $LogFile "[ERROR]" $LogMessage
		exit 1
	}

	# Get the Config entry
	$ConfigLine = GetConfig $ConfigFile $Key
	if ($ConfigLine.Trim() -eq "") {
		$LogMessage = $("Missing Config entry: " + $Key)
		WriteLog $LogFile "[ERROR]" $LogMessage
		exit 1
	}
	
	# Split the Config entry into components
	$Config = $ConfigLine.split($ConfigSplit)
	$FileLoadName = $Config[2]
	$FileBackupName = $Config[3]
	$FileLoad = $Config[5]
	$FileBackup = $Config[6]
	$AnaplanAction = $Config[7]
	$Notify = $Config[8].ToUpper()
	$NotifyEmail = $Config[9]
	$ActionType = $Config[10].ToUpper()
	$ExportFile = $Config[11]
	$JDBCConfig = $Config[12]
	$WorkspaceGUID = $Config[13]
	$ModelGUID = $Config[14]
	
	# Uncomment the below lines to keep a transient copy of the STDOUT and STDERR files
	#$TimeStamp = GetDateTimeStamp "yyyyMMddHHmmss"
	#$STDOUTFile = $($STDOUTFile + "_" + $TimeStamp)
	#$STDERRFile = $($STDERRFile + "_" + $TimeStamp)
	
	# Check if a file action is defined
	if ($AnaplanAction -eq "") {
		$LogMessage = $("Missing Action entry for: " + $Key)
		WriteLog $LogFile "[ERROR]" $LogMessage
		exit 1
	}	
		
	# Call the Anaplan Actions
	$TimeStamp = GetDateTimeStamp "yyyyMMddHHmmss"
	$ExceptionFile = $($ExceptionDir + "\Exception_" + $TimeStamp + ".txt")
	
	$LogMessage = $("[Workspace | Model] " + $WorkspaceGUID + " | " + $ModelGUID + " : " + "Perform processing Action: " + $AnaplanAction)
	WriteLog $LogFile "[INFO]" $LogMessage
	try {
		# Update the Action Log
		Start-Process "cmd" -ArgumentList '/c',$AnaplanConnectActionTimes,$AnaplanAction,$WorkspaceGUID,$ModelGUID -Wait -NoNewWindow -RedirectStandardOutput $STDOUTFile -RedirectStandardError $STDERRFile
			
		# Perform the main Anaplan Action
		if ($ActionType -eq "IMPORT") {

			$FileLoadNameCount = $FileLoadName.split($FileSplit).Count
			
			if ($FileLoadNameCount -eq 1) {
				$FileLoadNameIndex = $FileLoadName.split($FileSplit)[0]
				
				# Check if a file is available
				if ($FileLoad.Trim() -ne "" -and $FileLoadNameIndex.Trim() -ne "") {
					$Source = $($FileLoad + $FileLoadNameIndex)
					if (!(Test-Path $Source)) {
						$LogMessage = $("How come we came here when file is not there: " + $Source)
						WriteLog $LogFile "[ERROR]" $LogMessage
						exit 1
					} 
				}
				
				Start-Process "cmd" -ArgumentList '/c',$AnaplanConnectAction,$ActionType,$WorkspaceGUID,$ModelGUID,$FileLoadNameIndex,$Source,$AnaplanAction,$ExceptionFile -Wait -NoNewWindow -RedirectStandardOutput $STDOUTFile -RedirectStandardError $STDERRFile
			} else {
				$LogMessage = $("IMPORT can be done only for one file, use IMPORTANDPROCESS instead : " + $Config)
				WriteLog $LogFile "[ERROR]" $LogMessage
				exit 1
			}
			
		} elseif ($ActionType -eq "IMPORTANDPROCESS") {

			$ActionString = ""
			foreach($FileLoadNameIndex in $FileLoadName.split($FileSplit)) {
				# Check if a file is available
				if ($FileLoad.Trim() -ne "" -and $FileLoadNameIndex.Trim() -ne "") {
					$Source = $($FileLoad + $FileLoadNameIndex)
					if (!(Test-Path $Source)) {
						$LogMessage = $("How come we came here when file is not there: " + $Source)
						WriteLog $LogFile "[ERROR]" $LogMessage
						exit 1
					} 
				}
				
				# Build ActionString
				$ActionString = $($ActionString + " -file " + $FileLoadNameIndex + " -put " + $Source)
			}

			Start-Process "cmd" -ArgumentList '/c',$AnaplanConnectAction,$ActionType,$WorkspaceGUID,$ModelGUID,`"$ActionString`",$AnaplanAction,$ExceptionFile -Wait -NoNewWindow -RedirectStandardOutput $STDOUTFile -RedirectStandardError $STDERRFile		
			
		} elseif ($ActionType -eq "EXPORT") {
		
			Start-Process "cmd" -ArgumentList '/c',$AnaplanConnectAction,$ActionType,$WorkspaceGUID,$ModelGUID,$AnaplanAction,$ExportFile -Wait -NoNewWindow -RedirectStandardOutput $STDOUTFile -RedirectStandardError $STDERRFile

		} elseif ($ActionType -eq "ACTION") {
			
			Start-Process "cmd" -ArgumentList '/c',$AnaplanConnectAction,$ActionType,$WorkspaceGUID,$ModelGUID,$AnaplanAction,$ExceptionFile -Wait -NoNewWindow -RedirectStandardOutput $STDOUTFile -RedirectStandardError $STDERRFile			

		} elseif ($ActionType -eq "PROCESS") {
			
			Start-Process "cmd" -ArgumentList '/c',$AnaplanConnectAction,$ActionType,$WorkspaceGUID,$ModelGUID,$AnaplanAction,$ExceptionFile -Wait -NoNewWindow -RedirectStandardOutput $STDOUTFile -RedirectStandardError $STDERRFile			

		} elseif ($ActionType -eq "JDBCIMPORT" -or $ActionType -eq "JDBCPROCESS") {
			
			# Get the SQL Config entry
			$SQLConfigLine = GetConfig $SQLConfigFile $JDBCConfig
			if ($SQLConfigLine.Trim() -eq "") {
				$LogMessage = $("Missing Config entry: " + $JDBCConfig)
				WriteLog $LogFile "[ERROR]" $LogMessage
				exit 1
			}

			$SQLConfig = $SQLConfigLine.split($ConfigSplit)
			$SQLConnection = $SQLConfig[1]

			if (Test-Path $($ConfigDir + $SQLConnection)) {
				$JDBCFile = GenerateSQLConfig $SQLConfigLine				
			} else {
				$LogMessage = $("Missing SQL Connection file: " + $SQLConnection)
				WriteLog $LogFile "[ERROR]" $LogMessage
				exit 1				
			}
		
			Start-Process "cmd" -ArgumentList '/c',$AnaplanConnectAction,$ActionType,$WorkspaceGUID,$ModelGUID,$FileLoadName,$JDBCFile,$AnaplanAction,$ExceptionFile -Wait -NoNewWindow -RedirectStandardOutput $STDOUTFile -RedirectStandardError $STDERRFile
			
		} elseif ($ActionType -eq "Custom") {
			
			Start-Process "cmd" -ArgumentList '/c',$AnaplanAction,$WorkspaceGUID,$ModelGUID,$ExceptionFile -Wait -NoNewWindow -RedirectStandardOutput $STDOUTFile -RedirectStandardError $STDERRFile
		}

	} catch {
    	$LogMessage = $("Error processing Action: " + $AnaplanAction + " Error: " + $_.Exception.Message)
		WriteLog $LogFile "[ERROR]" $LogMessage
		exit 1
	}
	
	# Parse the AnaplanConnect output
	$AnaplanReturn = Get-Content $STDOUTFile
	$EmailStatus = ""
	
	if ($AnaplanReturn -match "The operation was successful" -and $AnaplanReturn -match "Dump file written to") {
		$EmailStatus = "Success with data errors"
		$LogMessage = $("Action completed successfully, but data errors occured: " + $AnaplanAction)
		WriteLog $LogFile "[INFO]" $LogMessage
	} elseif ($AnaplanReturn -match "The operation was successful") {
		$EmailStatus = "SUCCESS"
		$LogMessage = $("Action completed successfully: " + $AnaplanAction)
		WriteLog $LogFile "[INFO]" $LogMessage
	} else {
		$EmailStatus = "FAIL"
    	$LogMessage = $("Error running task: " + $Source + " using Action: " + $AnaplanAction + " Error: " + $AnaplanReturn)
		WriteLog $LogFile "[ERROR]" $LogMessage	
	}
	
	# Send an email notification if required
	$SendEmail = "FALSE"

	if ($Notify.Trim() -eq "SUCCESS" -and $EmailStatus -eq "SUCCESS") {
		$SendEmail = "TRUE"
	}
	if ($Notify.Trim() -eq "FAIL" -and $EmailStatus -eq "FAIL") {
		$SendEmail = "TRUE"
	}
	if ($Notify.Trim() -eq "BOTH") {
		$SendEmail = "TRUE"
	}		
		
	if ($SendEmail -eq "TRUE") {		
		$Result = EmailNotify $NotifyEmail $EmailStatus $FileLoadName $AnaplanAction $ExceptionFile
		
		if ($Result -eq "") {
			$LogMessage = $("Email notify: SUCCESS")
			WriteLog $LogFile "[INFO]" $LogMessage		
		} else {
			$LogMessage = $("Email notify: FAIL")
			WriteLog $LogFile "[ERROR]" $LogMessage
		} 
	}
	
	# Check if the DateStamp backup folder exists, if not create it
	if ($FileBackup.Trim() -ne "" -and $FileBackupName.Trim() -ne "") {
		$Backup = $($FileBackup + $DateStamp + "\")
		
		if (!(Test-Path -path $Backup)) {
			New-Item $Backup -Type Directory
		}
		
		# Iterate through all the files and Backup
		$IndexCount = $FileBackupName.split($FileSplit).Count
		for ($i=0; $i -lt $IndexCount; $i++) {				
			$FileLoadNameIndex = $FileLoadName.split($FileSplit)[$i]
			$FileBackupNameIndex = $FileBackupName.split($FileSplit)[$i]

			$Source = $($FileLoad + $FileLoadNameIndex)
			$FileBackupNextName = GetNextFileName $Backup $FileBackupNameIndex
			$Dest = $($Backup + $FileBackupNextName)
			
			# Backup the file
			$LogMessage = $("Backing-up file from: " + $Source + " to: " + $Dest)
			WriteLog $LogFile "[INFO]" $LogMessage
			try {
				Copy-Item -Path $Source -Destination $Dest -Force -ErrorAction Stop
			} catch {
				$LogMessage = $("Error copying file from: " + $Source + " to: " + $Dest + " Error: " + $_.Exception.Message)
				WriteLog $LogFile "[ERROR]" $LogMessage
				exit 1
			}
			
			$LogMessage = $("Backed-up file from: " + $Source + " to: " + $Dest)
			WriteLog $LogFile "[INFO]" $LogMessage
		}
	}
}

# Call the Main
main
