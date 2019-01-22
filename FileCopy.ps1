######################################################################
# This script does a simple file move based on the passed parameter
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
    Write-Host "Error while loading supporting PowerShell Scripts" + $_.Exception.Message
	exit 1
}

# Prepare any variables
$DateStamp = GetDateTimeStamp "yyyyMMdd"
$LogFile = $($LogDir + "\FileCopy_" + $DateStamp + ".log")

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
	$FilePattern = $Config[1]
	$FileDestName = $Config[2]
	$FileInbound = $Config[4]
	$FileLoad = $Config[5]

	# Validate
	if ($FilePattern.Trim() -eq "" -or $FileDestName.Trim() -eq "" -or $FileInbound.Trim() -eq "" -or $FileLoad.Trim() -eq "") {
		$LogMessage = $("Missing Config entries in: " + $ConfigLine)
		WriteLog $LogFile "[ERROR]" $LogMessage
		exit 1
	}
	
	# Check if a file(s) are available
	$Result = GetFileName $FileInbound $FilePattern
	if ($Result -eq "" -or $Result.StartsWith("Error")) {
		$LogMessage = $("How did we come here when file not found: " + $FileInbound + $FilePattern)
		WriteLog $LogFile "[ERROR]" $LogMessage
		exit 1
	} 
	
	# Validate
	$FilePatternCount = $FilePattern.split($FileSplit).Count
	$FileDestNameCount = $FileDestName.split($FileSplit).Count

	if ($FilePatternCount -ne $FileDestNameCount ) {
		$LogMessage = $("Invalid Config entries in: " + $ConfigLine)
		WriteLog $LogFile "[ERROR]" $LogMessage
		exit 1
	}
		
	# Move the file from Source to Destination
	$IndexCount = $FilePatternCount 	
	for ($i=0; $i -lt $IndexCount; $i++) {
		$FilePatternIndex = $FilePattern.split($FileSplit)[$i]
		$FileDestNameIndex = $FileDestName.split($FileSplit)[$i]
		
		$Result = GetSingleFileName $FileInbound $FilePatternIndex
		$Source = $($FileInbound + $Result)
		$Dest = $($FileLoad + $FileDestNameIndex)
		$LogMessage = $("Moving file from: " + $Source + " to: " + $Dest)
		WriteLog $LogFile "[INFO]" $LogMessage
		
		try {
			Move-Item -Path $Source -Destination $Dest -Force -ErrorAction Stop
		} catch {
			$LogMessage = $("Error moving file from: " + $Source + " to: " + $Dest + " Error: " + $_.Exception.Message)
			WriteLog $LogFile "[ERROR]" $LogMessage
			exit 1
		}
		
		$LogMessage = $("Moved file from: " + $Source + " to: " + $Dest)
		WriteLog $LogFile "[INFO]" $LogMessage
	}
}

# Call the Main
main
