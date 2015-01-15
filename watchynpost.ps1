# Directory Monitor
# Chris Roberts <chris@naxxfish.eu>
#
# This watches a directory using FileSystemWatcher and splurges out events whenever they happen.
#
# Usage: .\watchynpost.ps1 -Folder <folder to watch>
#
param(
	[string]$Folder, 
	[string]$Filter="*",
	[string]$Url = "http://zinc.naxxfish.net:9615/thingy" # might want to change this..
)

Write-Host "Directory Watcher"

$global:url = $Url

if (-not($Folder))
{
	$Folder = Read-Host -Prompt "Enter the path you wish to monitor for changes"
}

if ( -not (Test-Path $Folder)) {
    Write-Host "Not a valid path D:" -BackgroundColor Red -ForegroundColor White
    Exit
}
$global:folder = $Folder
# remove all existing events
Get-EventSubscriber | Unregister-Event | out-null

$fsw = New-Object IO.FileSystemWatcher $Folder, $Filter -Property @{IncludeSubdirectories = $true;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'} 

Write-Host "Registering FileSystemWatcher to watch for new files in $Folder" -BackgroundColor DarkGreen -ForegroundColor White
$client = New-Object System.Net.WebClient
Add-Type -AssemblyName System.Web	
Register-ObjectEvent $fsw Changed -SourceIdentifier FileChanged -Action { 
	$name = $Event.SourceEventArgs.Name 
	$changeType = $Event.SourceEventArgs.ChangeType 
	$timeStamp = $Event.TimeGenerated
	$filecontent = Get-Content "$global:folder\$name"
	$filecontent = [System.Web.HttpUtility]::UrlEncode($filecontent)
	$requestParams = "filename=$name&data=$filecontent"
	Write-Host "HTT POST to $global:url"
	Write-Host "Params: $requestParams"
	$result = $client.UploadString($global:url,$requestParams)
	Write-Host "Done"
	$True
}  | out-null


try {
	while (Wait-event File*) {
		Write-Host "-"
	 }
} finally {
	Get-EventSubscriber | Unregister-Event | out-null
	Write-Host "Exiting..."
}

