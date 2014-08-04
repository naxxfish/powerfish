# Directory Monitor
# Chris Roberts <chris@naxxfish.eu>
#
# This watches a directory using FileSystemWatcher and splurges out events whenever they happen.
#
# Usage: .\watchy.ps1 -Folder <folder to watch>
#
param([string]$Folder)
Write-Host "Directory Watcher"


if (-not($Folder))
{
	$Folder = Read-Host -Prompt "Enter the path you wish to monitor for changes"
}
$filter = "*"

if ( -not (Test-Path $Folder)) {
    Write-Host "Not a valid path D:" -BackgroundColor Red -ForegroundColor White
    Exit
}

# remove all existing events
Get-EventSubscriber | Unregister-Event | out-null

$fsw = New-Object IO.FileSystemWatcher $Folder, $filter -Property @{IncludeSubdirectories = $true;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'} 

Write-Host "Registering FileSystemWatcher to watch for new files in $Folder" -BackgroundColor DarkGreen -ForegroundColor White

Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action { 
	$name = $Event.SourceEventArgs.Name 
	$changeType = $Event.SourceEventArgs.ChangeType 
	$timeStamp = $Event.TimeGenerated 
	Write-Host "$timeStamp : $changeType : $name " -fore green 
}  | out-null

Register-ObjectEvent $fsw Changed -SourceIdentifier FileChanged -Action { 
$name = $Event.SourceEventArgs.Name 
$changeType = $Event.SourceEventArgs.ChangeType 
$timeStamp = $Event.TimeGenerated 
Write-Host "$timeStamp : $changeType : $name " -fore yellow }  | out-null

Register-ObjectEvent $fsw Renamed -SourceIdentifier FileRenamed -Action { 
$name = $Event.SourceEventArgs.Name 
$changeType = $Event.SourceEventArgs.ChangeType 
$timeStamp = $Event.TimeGenerated 
Write-Host "$timeStamp : $changeType : $name " -fore yellow }  | out-null

Register-ObjectEvent $fsw Deleted -SourceIdentifier FileDeleted -Action { 
$name = $Event.SourceEventArgs.Name 
$changeType = $Event.SourceEventArgs.ChangeType 
$timeStamp = $Event.TimeGenerated 
Write-Host "$timeStamp : $changeType : $name " -fore red 
}  | out-null

try {
	while (Wait-event File*) {
		Write-Host "-"
	 }
} finally {
	Get-EventSubscriber | Unregister-Event | out-null
	Write-Host "Exiting..."
}

