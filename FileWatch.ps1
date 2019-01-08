######################################################################
# This script does a simple file watch based on the passed parameter
# Author: 	Upali Wickramasinghe
# Version: 	0.2
# Date:		02/11/2018
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
	$Config = $ConfigLine.split($ConfigSplit)
	$FilePattern = $Config[1]
	$FileInbound = $Config[4]
	
	# Validate
	if ($FilePattern.Trim() -eq "" -or $FileInbound.Trim() -eq "") {
		$LogMessage = $("Missing Config entries in: " + $ConfigLine)
		WriteLog $LogFile "[ERROR]" $LogMessage
		exit 1
	}
	
	# Check if a file(s) are available
	$Result = GetFileName $FileInbound $FilePattern
	if ($Result -eq "") {
		exit 1
	} elseif ($Result.StartsWith("Error")) {
		WriteLog $LogFile "[INFO]" $Result
		exit 1
	} else {
		$LogMessage = $("Found file(s): " + $FileInbound + $Result)
		WriteLog $LogFile "[INFO]" $LogMessage
	}
}

# Call the Main
main
