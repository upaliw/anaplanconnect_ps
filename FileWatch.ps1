######################################################################
# This script does a simple file watch based on the passed parameter
# Author: 	Upali Wickramasinghe
# Version: 	0.1
# Date:		15/06/2018
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
    Write-Host "Error while loading supporting PowerShell Scripts" 
	exit 1
}

# Prepare any variables
$DateStamp = GetDateTimeStamp "yyyyMMdd"
$LogFile = $($LogDir + "\FileWatch_" + $DateStamp + ".log")

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
	$config = $ConfigLine.split($ConfigSplit)
	$FilePattern = $config[1]
	$FileInbound = $config[4]
	
	# Check if a file is available
	$result = GetFileName $FileInbound $FilePattern
	if ($result -eq "") {
		exit 1
	} else {
		$LogMessage = $("Found file: " + $FileInbound + $result)
		WriteLog $LogFile "[INFO]" $LogMessage
	}
}

# Call the Main
main
