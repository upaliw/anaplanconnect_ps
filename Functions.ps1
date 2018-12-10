######################################################################
# This is a generic set of re-usable functions
# Author: 	Upali Wickramasinghe
# Version: 	0.2
# Date:		29/10/2018
######################################################################

# Define any constants
$ConfigFile 	= ".\FileInterfaces.ini"
$ConfigSplit 	= ";"
$FileSplit		= "|"
$NotificationFile = ".\EmailNotifications.ini"
$NotificationSplit= "="
$LogDir 		= ".\logs"
$ExceptionDir	= "exceptions"
$AnaplanConnectActionTimes = ".\ActionTimes.bat"
$AnaplanConnectAction = ".\AnaplanAction.bat"
$STDOUTFile		= ".\stdout.txt"
$STDERRFile		= ".\stderr.txt"

# Get a Date or Time using the format provided
function GetDateTimeStamp($Format) {
	return Get-Date -f $Format
}

# Write to a log file, create if doesn't exist or append if does
function WriteLog($LogFile, $LogType, $LogMessage) {
	$TimeStamp = GetDateTimeStamp "yyyyMMdd HH:mm:ss"
	$LogString = $($LogType + " " + $TimeStamp + " :: " + $LogMessage)
	
	if (!(Test-Path $LogFile)) {
		$LogString > $LogFile
	}
	else {
		$LogString >> $LogFile
	}
}

# Get the Config line as a String
function GetConfig($ConfigFile, $Key) {
	$Result = ""
	
	foreach($Line in Get-Content $ConfigFile) {
		if ($Line.StartsWith(" ") -or $Line.StartsWith("#")) {continue}
		
		$Config = $Line.split($ConfigSplit)
		if ($Config[0] -eq $Key) {
			$Result = $Line
			break
		}
	}
	
	return $Result
}

# Get the name of a file using a RegEx
function GetFileName($FileLocation, $FilePattern) {
	$Result = ""
	$FileCount = $FilePattern.split($FileSplit).Count
	
	$Files = Get-ChildItem $FileLocation
	$FileFound = 0
	foreach($File in $Files) {
		foreach($FilePatternItem in $FilePattern.split($FileSplit)) {
			if ($File.Name -match $FilePatternItem) {
				$FileFound = $FileFound + 1
				$Result = $($Result + " (" + $FileFound + "/" + $FileCount + ") " + $File.Name)
			}
		}
	}
	
	if ($FileFound -gt 0 -and $FileCount -gt $FileFound) {
		$Result = $("Error: Not all files found " + $Result)
	}
	
	return $Result
}

# Get the name of single file using a RegEx
function GetSingleFileName($FileLocation, $FilePattern) {
	$Result = ""
	
	$Files = Get-ChildItem $FileLocation
	foreach($File in $Files) {		
		if ($File.Name -match $FilePattern) {
			$Result = $File.Name
		}
	}
	
	return $Result
}

# Get the new name of a file to use as incremental in copy
function GetNextFileName($FileLocation, $FileName) {
	$Result = ""
	
	if (Test-Path $($FileLocation + $FileName)) {
		$Dest = $($FileLocation + $FileName.Substring(0, $FileName.Length - 4) + "*")
		
		$Latest = Get-ChildItem -Path $Dest| Sort-Object Name -Descending | Select-Object -First 1
		#split the latest filename, increment the number, then re-assemble new filename:
		$Result = $Latest.BaseName.Split('_')[0] + "_" + ([int]$Latest.BaseName.Split('_')[1] + 1).ToString().PadLeft(4, "0") + $Latest.Extension
	}
	
	return $Result
}

# Send email notification if required
function EmailNotify($NotifyEmail, $EmailStatus, $FileLoadName, $FileLoadAction, $ExceptionFile) {
	# Read the required parameters
	$Result = ""
	$SMTP = ""
	$Port = 0
	$From = ""
	$To = $NotifyEmail
	$Subject = ""
	$Body = ""
	$SSL = ""
	
	foreach($Line in Get-Content $NotificationFile) {
		if ($Line.StartsWith(" ") -or $Line.StartsWith("#")) {continue}
		
		$Config = $Line.split($NotificationSplit)
		if ($Config[0] -eq "SMTP") {$SMTP = $Config[1]}
		if ($Config[0] -eq "PORT") {$Port = [int]$Config[1]}
		if ($Config[0] -eq "FROM") {$From = $Config[1]}
		if ($Config[0] -eq "SUBJECT") {$Subject = $Config[1]}
		if ($Config[0] -eq "BODY") {$Body = $Config[1]}
		if ($Config[0] -eq "SSL") {$SSL = $Config[1].ToUpper()}
	}
	
	if ($SMTP.Trim() -ne "" -and $From.Trim() -ne "" -and $To.Trim() -ne "" -and $Subject.Trim() -ne "" -and $Body.Trim() -ne "") {
		$Subject = $($EmailStatus + ":: " +$Subject + " on Action: " + $FileLoadName + " using: " + $FileLoadAction)
		
		# Send email
		try {		
			$SMTPMessage = New-Object System.Net.Mail.MailMessage($From, $To, $Subject, $Body)

			if (Test-Path $ExceptionFile) {
				$Folder = (Get-Item $ExceptionFile) -is [System.IO.DirectoryInfo]
				if ($Folder) {
					foreach ($File in Get-ChildItem $($ExceptionFile + "\")) {
						$Attachment = New-Object System.Net.Mail.Attachment($($ExceptionFile + "\" + $File))
						$SMTPMessage.Attachments.Add($Attachment)
					}
				} else {
					$FilenameAndPath = $ExceptionFile
					$Attachment = New-Object System.Net.Mail.Attachment($FilenameAndPath)
					$SMTPMessage.Attachments.Add($Attachment)
				}
			} 
			
			$SMTPClient = New-Object Net.Mail.SmtpClient($SMTP, $Port)
			if ($SSL -eq "FALSE") {
				$SMTPClient.EnableSsl = $False
			} else {
				$SMTPClient.EnableSsl = $True 
			}
			
			$PasswordFile = ".\EmailPassword.txt"
			if ((Get-Content $PasswordFile) -ne $Null) {
				$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $From, (Get-Content $PasswordFile | ConvertTo-SecureString)
				$SMTPClient.Credentials = New-Object System.Net.NetworkCredential($Cred.UserName, $Cred.Password);
			} else {
				$SMTPClient.UseDefaultCredentials = $True
			}

			$SMTPClient.Send($SMTPMessage)
						
		} catch {
			Write-Host "Error while sending email Error: " + $_.Exception.Message
			$Result = "Fail"
		}
	}
	return $Result
}