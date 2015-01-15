# Directory Monitor
# Chris Roberts <chris@naxxfish.eu>
#
# This watches a directory using FileSystemWatcher and HTTP post the contents of the file (urlencoded)
#
# Usage: .\watchynpost.ps1 -Folder <folder to watch> -Filter <filename filter> -Url http://where.you.want.it.to/go 
#
# the HTTP POST parameters are "filename" and "data" - which are what you might expect them to be :)
param(
	[string]$Folder, 
	[string]$Url,
	[string]$Filter="*"
)

Write-Host "Directory Watcher"

$global:url = $Url
if (-not($Url))
{
	$Url = Read-Host -Prompt "Enter the URL you want to HTTP POST to"
}
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

Add-Type -AssemblyName System.Web
function global:UploadFile([string]$name)
{
	try {
		$client = New-Object System.Net.WebClient
		# Write-Host $name
		$filecontent = Get-Content "$global:folder\$name"
		$filecontent = [System.Web.HttpUtility]::UrlEncode($filecontent)
		$requestParams = "filename=$name&data=$filecontent"
		Write-Host "HTTP POST to $global:url"
		Write-Host "Params: $requestParams"
		$result = $client.UploadString($global:url,$requestParams)
		Write-Host "Done $result"
		$client = $null
	} catch [Exception]
	{
		Write-Host $_.GetType().FullName
		Write-Host $_.Exception.Message
	}
}
# Trigger on file modification
Register-ObjectEvent $fsw Changed -SourceIdentifier FileChanged -Action { 
		UploadFile($Event.SourceEventArgs.Name)
		$changeType = $Event.SourceEventArgs.ChangeType 
		$timeStamp = $Event.TimeGenerated
		
}  | out-null
# Trigger on file renaming (ehh...)
Register-ObjectEvent $fsw Renamed -Action { 
		UploadFile($Event.SourceEventArgs.Name)
		$changeType = $Event.SourceEventArgs.ChangeType 
		$timeStamp = $Event.TimeGenerated
		
}  | out-null


try {
	while (Wait-event File*) {
		Write-Host "-"
	 }
} finally {
	Get-EventSubscriber | Unregister-Event | out-null
	Write-Host "Exiting..."
}

