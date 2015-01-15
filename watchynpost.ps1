# Directory Monitor
# Chris Roberts <chris@naxxfish.eu>
#
# This watches a directory using FileSystemWatcher and splurges out events whenever they happen.
#
# Usage: .\watchynpost.ps1 -Folder <folder to watch>
#
param([string]$Folder)
Write-Host "Directory Watcher"

$global:url = "http://zinc.naxxfish.net:9615/thingy" # REPLACE THIS WITH YOUR PATH!

if (-not($Folder))
{
	$Folder = Read-Host -Prompt "Enter the path you wish to monitor for changes"
}
$filter = "*"

if ( -not (Test-Path $Folder)) {
    Write-Host "Not a valid path D:" -BackgroundColor Red -ForegroundColor White
    Exit
}
$global:folder = $Folder
# remove all existing events
Get-EventSubscriber | Unregister-Event | out-null

$fsw = New-Object IO.FileSystemWatcher $Folder, $filter -Property @{IncludeSubdirectories = $true;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'} 

Write-Host "Registering FileSystemWatcher to watch for new files in $Folder" -BackgroundColor DarkGreen -ForegroundColor White
$client = New-Object System.Net.WebClient
Add-Type -AssemblyName System.Web	
Register-ObjectEvent $fsw Changed -SourceIdentifier FileChanged -Action { 
	$name = $Event.SourceEventArgs.Name 
	$changeType = $Event.SourceEventArgs.ChangeType 
	$timeStamp = $Event.TimeGenerated
	$filecontent = Get-Content "$global:folder\$name"
	Write-Host $filecontent
	Write-Host "hello"
	$requestParams = "filename=$name&data=", [System.Web.HttpUtility]::UrlEncode($filecontent)
	Write-Host "Params: $requestParams"


	Write-Host "Sending to $global:url"
	$result = $client.UploadString($global:url,$requestParams)
	$result
}  | out-null


try {
	while (Wait-event File*) {
		Write-Host "-"
	 }
} finally {
	Get-EventSubscriber | Unregister-Event | out-null
	Write-Host "Exiting..."
}

