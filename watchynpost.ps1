# Directory Monitor
# Chris Roberts <chris@naxxfish.eu>
#
# This watches a directory using FileSystemWatcher and splurges out events whenever they happen.
#
# Usage: .\watchynpost.ps1 -Folder <folder to watch>
#
param([string]$Folder)
Write-Host "Directory Watcher"

$url = "http://naxx.fish/hello" # REPLACE THIS WITH YOUR PATH!

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

Register-ObjectEvent $fsw Changed -SourceIdentifier FileChanged -Action { 
	$name = $Event.SourceEventArgs.Name 
	$changeType = $Event.SourceEventArgs.ChangeType 
	Write-Host $name
	Write-Host  "$global:folder\$name"
	$timeStamp = $Event.TimeGenerated
	$content = "filename=$name&data=" + [System.Web.HttpUtility]::UrlEncode(Get-Content "$global:folder\$name")
	
	$parameters =  $content	# your POST parameters
	Write-Host $content
	
	$http_request = New-Object -ComObject Msxml2.XMLHTTP
	$http_request.open('POST', $url, $false)
	$http_request.setRequestHeader("Content-type",
	"application/x-www-form-urlencoded")
	$http_request.setRequestHeader("Content-length", $parameters.length)
	$http_request.setRequestHeader("Connection", "close")
	$http_request.send($parameters)
	$http_request.statusText
	Write-Host $http_request.statusText
}  | out-null


try {
	while (Wait-event File*) {
		Write-Host "-"
	 }
} finally {
	Get-EventSubscriber | Unregister-Event | out-null
	Write-Host "Exiting..."
}

