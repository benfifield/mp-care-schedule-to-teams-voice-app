#######################################################################################
# POC Call Queue Automation
#
# This Powershell script interacts with the MinistryPlatform API to run a custom API
# procedure to get the email address of the current Pastor on Call. It then sets
# that person as the TimeoutActionTarget and OverflowActionTarget for a call queue
# and the Redirect destination for the after hours call flow of an auto attendant.
#
#######################################################################################

# Authentication Variables
$mpBaseDomain = "my.contoso.church"
$mpAPIClientID = "clientid"
$mpAPIClientSecret = "clientsecret"
$teamsAdminUsername = "teamsadminuser@contoso.church"
$teamsAdminPassword = ConvertTo-SecureString -String "password" -AsPlainText -Force

# Control Variables
$mpAPIProcess = "api_CUSTOM_GetPOCContactEmail"
$expectedStaffUPNSuffix = "contoso.church"
# Set either of these variables to "" if you want to skip that step
$teamsCallQueueIdentityGUID = "guid" #Can be found by running Get-CSCallQueue -Name "{Name of Call Queue}"
$teamsAutoAttendantIdentityGUID = "guid" #Can be found by running Get-CSAutoAttendant -Name "{Name of Auto Attendant}"

$logFile = "log.txt"


function Get-MpToken {
	param (
		$ClientID,
		$ClientSecret,
		$BaseDomain
	)
	
	$authMethod = "Post"
	$authUri = "https://$BaseDomain/ministryplatformapi/oauth/connect/token"
	$authContentType = "application/x-www-form-urlencoded"
	$authBody = @{
		"grant_type"="client_credentials"
		"client_id"="$mpAPIClientID"
		"client_secret"="$mpAPIClientSecret"
		"scope"="http://www.thinkministry.com/dataplatform/scopes/all"
	}
	
	try {
		$Token = Invoke-RestMethod -Uri $authUri -Method $authMethod -ContentType $authContentType -Body $authBody -ErrorAction Stop | Select-Object -ExpandProperty access_token
	}
	catch {
		Write-Log "Failed to retrieve the Ministry Platform API authorization token."
		Write-Log $_
		Write-Error $_ -ErrorAction Stop
	}
	
	Write-Output $Token
}

function Initialize-Log {
	Param (
		[string]$LogString
	)
	
	$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	$LogMessage = "$Stamp $LogString"
	Set-Content $LogFile -value $LogMessage
}

function Write-Log {
	Param (
		[string]$LogString
	)
	
	$Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
	$LogMessage = "$Stamp $LogString"
	Add-Content $LogFile -value $LogMessage
}



Initialize-Log "Starting..."

Write-Log "Fetching Ministry Platform OAuth Token..."
$mpOAuthToken = Get-MpToken -ClientID $mpAPIClientID -ClientSecret $mpAPIClientSecret -BaseDomain $mpBaseDomain

Write-Log "Fetching the Pastor on Call email address from MinistryPlatform..."
$pocUri = "https://$mpBaseDomain/ministryplatformapi/procs/$mpAPIProcess"
$pocHeaders = @{"Authorization"= "Bearer $mpOAuthToken"}
try {
	$pocResponse = Invoke-RestMethod -Uri $pocUri -Headers $pocHeaders -ErrorAction Stop
} catch {
	Write-Log "Failed to execute the MinistryPlatform API Procedure"
	Write-Log $_
	Write-Error $_ -ErrorAction Stop
}

$pocName = $pocResponse.SyncRoot.Name
$pocEmail = $pocResponse.SyncRoot.Email
if ( $pocEmail -notlike "*$expectedStaffUPNSuffix" ) {
	Write-Log "Pastor on Call Email Address does not match the expected UPN Suffix"
	Write-Log "Returned email address: $pocEmail"
	Write-Error "Unexpected email address domain" -ErrorAction Stop
}

Write-Log "The currently assigned Pastor on Call in MinistryPlatform is $pocName - $pocEmail"

Write-Log "Connecting to Teams Powershell..."
$teamsCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $teamsAdminUserName, $teamsAdminPassword
try {
	Connect-MicrosoftTeams -Credential $teamsCredential -ErrorAction Stop
} catch {
	Write-Log "Failed to connect to Teams Powershell"
	Write-Log $_
	Write-Error $_ -ErrorAction Stop
}


Write-Log "Getting information about the Teams user..."
try {
	$pocTeamsIdentityGUID = Get-CsOnlineUser -Identity $pocEmail -ErrorAction Stop | Select-Object -ExpandProperty Identity
} catch {
	Write-Log "$pocEmail is not a valid Teams User"
	Write-Error -Message "$pocEmail is not a valid Teams User" -ErrorAction Stop
}


$updatesMade = 0

# Set the Call Queue TimeoutActionTarget and OverflowActionTarget
if ( $teamsCallQueueIdentityGUID -ne "" ) {
	try {
		$currentCallQueueTarget = Get-CSCallQueue -Identity $teamsCallQueueIdentityGUID | Select-Object -ExpandProperty TimeoutActionTarget
	} catch {
		Write-Log "$teamsCallQueueIdentityGUID is not a valid Call Queue GUID"
		Write-Error -Message "$teamsCallQueueIdentityGUID is not a valid Call Queue GUID" -ErrorAction Stop
	}
	if ( $currentCallQueueTarget.Id -ne $pocTeamsIdentityGUID ) {
		Write-Log "Updating Call Queue..."
		try {
			Set-CsCallQueue -Identity $teamsCallQueueIdentityGUID -TimeoutAction "Forward" -TimeoutActionTarget $pocTeamsIdentityGUID -OverflowAction "Forward" -OverflowActionTarget $pocTeamsIdentityGUID
		} catch {
			Write-Log "Failed to update Call Queue."
			Write-Log $_
			Write-Error $_ -ErrorAction Stop
		}
		$updatesMade++
	} else {
		Write-Log "Call queue did not need to be updated."
	}
}


# Set the Auto Attendant After Hours Call Flow redirect
if ( $teamsAutoAttendantIdentityGUID -ne "" ) {
	Write-Log "Getting the current Auto Attendant..."
	try {
		$autoAttendant = Get-CsAutoAttendant -Identity $teamsAutoAttendantIdentityGUID
	} catch {
		Write-Log "$teamsAutoAttendantIdentityGUID is not a valid Auto Attendant GUID"
		Write-Log $_
		Write-Error $_ -ErrorAction Stop
	}
	if ( $autoAttendant.CallFlows[0].Menu.MenuOptions.CallTarget.Id -ne $pocTeamsIdentityGUID ) {
		Write-Log "Updating Auto Attendant..."
		try {
			$autoAttendantPOCEntity = New-CsAutoAttendantCallableEntity -Identity $pocTeamsIdentityGUID -Type User
			$pocAutoAttendantMenuOptions = New-CsAutoAttendantMenuOption -Action TransferCallToTarget -DtmfResponse Automatic -CallTarget $autoAttendantPOCEntity
			$autoAttendant.CallFlows[0].Menu.MenuOptions = $pocAutoAttendantMenuOptions
			Set-CsAutoAttendant -Instance $autoAttendant
		} catch {
			Write-Log "Failed to update Auto Attendant"
			Write-Log $_
			Write-Error $_ -ErrorAction Stop
		}
		$updatesMade++
	} else {
		Write-Log "Auto Attendant did not need to be updated."
	}
}

if ( $updatesMade -gt 0 ) {
	Write-Log "Complete! Pastor on Call updated to : $pocName"
} else {
	Write-Log "No updates were made because the Pastor on Call is already set to: $pocName"
}