# Ping Monitor
# Chris Roberts <chris@naxxfish.eu>
#
# This script pings a host continually - but only marks when the host stops respoding to pings (DOWN) and then starts again (UP).  
#
#
param([string]$ip = "@@@", [switch]$quiet)
$oktime = get-date
$isup = $false
$firstrun = $true
$counter = 0
Write-Host " Ping Continuity Tester " -ForegroundColor White -BackgroundColor Red
Write-Host "    by Chris Roberts <chris@naxxfish.eu>" 
if ($ip -eq "@@@")
{
	$ip = Read-Host -Prompt "Enter the host you wish to monitor"
}
$ScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
$voice = new-object -com SAPI.SpVoice;
$remindCounter = 0
$lastState = ""
if ($quiet -ne $true)
{
	Write-Host "Sound ENABLED"
	$Voice.Speak( "Monitoring $ip ", 1 ) | out-null;
}
Write-Host "Started monitoring $ip for changes at $oktime" -ForegroundColor Yellow
while($true)
{
	$ok = Test-Connection -ComputerName $ip -Count 1 -erroraction silentlyContinue
	if ( -not($ok) ) {
		if ($isup)
		{
			Write-Host ""
			Write-Host "Host has gone down as of $oktime" -ForegroundColor RED
			$lastState = "$ip is down as of $oktime"
			if ($quiet -ne $true)
			{
				$Voice.Speak( "$ip has gone down", 1 ) | out-null;
			}
			$isup = $false
		}
	} else {
		if (-not($isup) )
		{
			$oktime = get-date
			
			if (-not ($firstrun)) { 
				Write-Host ""
				Write-Host "Host has come back up at $oktime" -ForegroundColor Green 
				
				if ($quiet -ne $true)
				{
					$Voice.Speak( "$ip has come up", 1 ) | out-null;	
				}
				}
			else { 
				$firstrun = $false 
				$lastState = "$ip is up since $oktime"
			}
			$isup = $true
		}
		$oktime = get-date
	}
	$counter = $counter + 1
	if ($counter -ge 5)
	{
		$remindCounter = $remindCounter + 1
		# play the file once
		$sndfile = "$ScriptRoot\sounds\ping.wav"
		if ($isup) { 
			Write-Host "." -NoNewline -BackgroundColor DarkGreen -ForegroundColor White
			$sndfile ="$ScriptRoot\ping.wav";
		} else { 
			Write-Host "x" -NoNewline -BackgroundColor DarkRed -ForegroundColor White
			$sndfile="$ScriptRoot\sounds\error.wav";
			if ($quiet -ne $true)
			{
				$Voice.Speak( "$ip down", 1 ) | out-null;
			}
		}		
		if ($quiet -ne $true)
		{
			$sound = new-Object System.Media.SoundPlayer;
			$sound.SoundLocation = $sndfile
			$sound.Play();
		}
		$counter = 0
	}
	if ($remindCounter -gt 5)
	{
		if ($quiet -ne $true)
		{
			Start-Sleep -s 2
			$Voice.Speak( $lastState, 1 ) | out-null;
		}
		$remindCounter = 0
	}
	Start-Sleep -s 3
}
