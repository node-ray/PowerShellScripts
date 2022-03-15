#A PowerShell script to automatically test-launch Citrix Apps, wait for the app to launch, and record the app launch as failed if not launched within a pre-configured timeout
#Scrapes the Citrix receiver logs for the app server name of the failed launch for further troubleshooting. Also tries to take a screenshot of the app launch error if there happens to be one 
#This requires the installation of AutoIt 64 bit, Citrix Workspace, and SelfService.exe logging enabled (https://support.citrix.com/article/CTX132883)

$app = "notepad_testtag" #exact name of Citrix App being tested
$windowTitle = "Untitled - Notepad - \\Remote" # Get this by using AutoIt v3 Window Info. Could probably also get away with just appending " - \\Remote"
$logPath = "C:\CitrixLogs\"
$appTimeout = 60 # How long to wait for the app to launch before considering it a "failed" app launch. 
$sleepTime = 5 # Sleep time beetween points of loading intervals. Increase this if the script doesn't behave as expected.
$userName = "ray" 

$launchTimes = @()
$failCount=0
$successCount=0
Set-Location $logPath
function Out-ToLogFile { Write-Output "$(get-date): $args" | Tee-Object $logPath\test.log -Append | write-host }
function Get-AppServerName { #function to scrape app server name from SelfService.exe log files

    $logFiles = (Get-ChildItem C:\Users\$userName\AppData\Local\Citrix\SelfService\auxtrace\*.* | Sort-Object LastWriteTime | Select-Object -last 15)
    $values = foreach($logfile in $logFiles) #for each loop piped back into a variable, scraping log files with server names in it
    {
        $string = (get-content $logfile)
        $Regex = [Regex]::new("(?<=Session-ServerName=)(.*)(?=,Session-UserName)")   #regex to extract matches for server names. Don't ask me how I figured this out. I don't remember        
        $Match = $Regex.Match($string)
        if($Match.Success)  #if server name is in a log file, add it to the list of values, otherwise omit blank values for log files without server name         
        {           
             $Match.Value           
        }
    }      
    
    $AppServerValue = ($values | Select-Object -last 1)
    #this code block handles log files with more than one server name
    if ($AppServerValue -match 'verbose=False'){ 
        $delimiter = "verbose=False" #picked an arbitrary delimiter between the two server values matched in a log file with two server names in it
        $AppServerString = ($AppServerValue -split $delimiter | Select-Object -last 1) #split string by delimiter and select the second half (most recent) of the log string
        $Regex = [Regex]::new("(?<=Session-ServerName=)(.*)") #regex to trim excess string before server name       
        $Match = $Regex.Match($AppServerString) #regex performed against $AppServerString
        if($Match.Success)  #set properly formatted server name as $AppServerName       
        {           
            $AppServerName = $Match.Value           
        }
    }
    else {
        $AppServerName = $AppServerValue #if the latest log file entry with a server name doesn't contain multiple server names, the server name is set as $AppServerName
    }
    return $AppServerName
}
function Get-ScreenCapture{ #function to take screenshot when app launch times out (to capture error messages that may be displayed) stored at C:\CitrixLogs\
    param(    
    [Switch]$OfWindow        
    )


    begin {
        Add-Type -AssemblyName System.Drawing
        $jpegCodec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | 
            Where-Object { $_.FormatDescription -eq "JPEG" }
    }
    process {
        Start-Sleep -Milliseconds 250
        if ($OfWindow) {            
            [Windows.Forms.Sendkeys]::SendWait("%{PrtSc}")        
        } else {
            [Windows.Forms.Sendkeys]::SendWait("{PrtSc}")        
        }
        Start-Sleep -Milliseconds 250
        $bitmap = [Windows.Forms.Clipboard]::GetImage()    
        $ep = New-Object Drawing.Imaging.EncoderParameters  
        $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality, [long]100)  
        $screenCapturePathBase = "$pwd\ScreenCapture"
        $c = 0
        while (Test-Path "${screenCapturePathBase}${c}.jpg") {
            $c++
        }
        $bitmap.Save("${screenCapturePathBase}${c}.jpg", $jpegCodec, $ep)
    }
}
while(1){


Out-ToLogFile "Launching App $app" ; SelfService.exe -qlaunch $app ; $stopwatch =  [system.diagnostics.stopwatch]::StartNew(); $sleepTime ; Out-ToLogFile "Waiting for App"

If((Wait-AU3Win $windowTitle -Timeout $appTimeout) -eq 0){
    $servername = (Get-AppServerName); Out-ToLogFile $servername
    Get-ScreenCapture # This doesn't always seem to work
    Out-ToLogFile "App Launch Timed Out after" ; $failCount++ ; Out-ToLogFile "Fail Count = $failCount"
}
Else{
    $timeToLaunch = $stopwatch.Elapsed.TotalSeconds
    $launchTimes += "$timeToLaunch"
    $launchTimeAverage = ($launchTimes | measure-object -average).Average
    $servername = (Get-AppServerName); Out-ToLogFile $servername
    Out-ToLogFile "App Launch Success" ;Out-ToLogFile "Took $timeToLaunch seconds to launch"; Out-ToLogFile "Average of $launchTimeAverage seconds per launch";$successCount++ 

}

$failRatio = ($failCount/($failCount+$successCount)).ToString("P") # Output failRatio as a percentage
Out-ToLogFile "Success Count = $successCount, Fail Count = $failCount, Fail Percentages = $failRatio"
Start-Sleep $sleepTime ; Out-ToLogFile "Logging Off Sessions" ; Selfservice.exe -logoffSessions ; Start-Sleep $sleepTime

Out-ToLogFile "Restarting Loop" ; Start-Sleep $sleepTime
}


sleep 