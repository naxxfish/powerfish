# Ping List Monitor
# Chris Roberts <chris.roberts1@bbc.co.uk>
#
# This script pings a list of hosts continually - but only marks when the host stops respoding to pings (DOWN) and then starts again (UP).  
#
#
param([string]$listFile, [switch]$Quiet)
if ($listFile -eq "")
{
	Write-Host "Need to provide a line seperated list of hosts as the first parameter!"
	Exit
}

if (-not(Test-Path $listFile))
{
	Write-Host "File doesn't exist"
	Exit
}

if (-not($Quiet))
{
	Write-Host "Sound ENABLED (pass -Quiet to disable)"
} else {
	Write-Host "Sound DISABLED (passed -Quiet)"
}

$ScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$voice = new-object -com SAPI.SpVoice;
try {
while($true)
{
	$hosts = Get-Content $listFile
	$jobs = @()
	ForEach ($myHost in $hosts)
	{
		$jobs += Start-Job -Arg $myHost, $Quiet {
			param([string]$myhostname, [switch]$Quiet)
			
			# Write-Host "Testing $myhostname"
			$ok = Test-Connection -ComputerName $myhostname -Count 1 -erroraction silentlyContinue
			
			if (-not($ok))
			{		
				"$myhostname DOWN"
			} else {
				$time = [System.Math]::Round(($ok | Measure-Object ResponseTime -average).average)
				"$myhostname up ($time ms)"
			}

		}
	}
	$complete = $false
	Clear-Host
	Write-Host "Pingtest Results"
	Write-Host "Pinging ", $hosts.Count , " hosts"
	Write-Host "-----------------"
	$downHosts = 0
	$upHosts = 0
	while( -not($complete))
	{
		$arrayJobsComplete = Get-Job | 
        Where-Object { $_.State -match 'Complete' }
		$arrayJobsInProgress = Get-Job | 
        Where-Object { $_.State -match 'Running'}
		ForEach ($job in $arrayJobsComplete) {
			if($job -ne $null)
			{
				$output = $job | Receive-Job
				if ($output -like '*DOWN')
				{
					$downHosts +=1 
					Write-Host $output -Foregroundcolor RED
				} else {
					$upHosts +=1
					Write-Host $output -ForegroundColor Green
				}
				Remove-Job  -Job $job
			}
		}
		if (-not $arrayJobsInProgress) { 
			Write-Host "Up hosts: $upHosts"
			Write-Host "Down hosts: $downHosts"
			$hostCount = $hosts.Count
			if (-not($Quiet))
			{
				$message = ""
				if ($downHosts -eq 0)
				{
					$sndfile = "$ScriptRoot\sounds\ping.wav"
					$message = "All hosts up"
					
				} else {
					$sndfile = "$ScriptRoot\sounds\error.wav"
					$message = "$downHosts of $hostCount hosts are down"
				}
				$sound = new-Object System.Media.SoundPlayer;
				$sound.SoundLocation = $sndfile
				$sound.Play();
				Start-Sleep -Milliseconds 400
				$Voice.speak($message, 1) | Out-Null
			}
			"------------------" ; 
			$complete = $true 
			
			} 
		Start-Sleep -milliseconds 50
	}
	Start-Sleep -s 30
}
} finally {
	Write-Host "Exiting..."
	Get-Job | Remove-Job 
}