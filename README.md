# PowerShellScripts
A collection of scripts created/scavenged during work in my home lab

## CitrixTest.ps1
A script that uses the AutoIt PowerShell module to test-launch Citrix Apps, detect for failures, scraping the Citrix receiver logs for the app server name of the failed launch, and tries to take a screenshot of an error related to the app not launching. 

## Reset-WindowsUpdate.ps1
A script salvaged from the now-retired Microsoft TechNet Repository - Useful in repairing Windows updates when other repair methods have failed. Use with caution (take a snapshot and potentially run individual lines separately to see what works for you).

## Retrieve-AllEvents.ps1
A script salvaged from the now-retired Microsoft TechNet Repository - Useful for dumping the event logs when troubleshooting an issue such as lock-ups (look at the last events in the log before the lock-up occurs), or where events from various other event logs (that do not show up in the Administrative Events System/Application logs) may affect each other. 

## WindowsServiceCheck.ps1
A script for checking Windows services that can be used to automate post-patching checks with automation tools like AWS SSM (using the exit code), or combined with email functionality for simple alerting. 
