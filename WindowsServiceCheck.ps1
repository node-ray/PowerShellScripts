# A PowerShell script that can be run after patching/rebooting to check to verify that services are up. This can be combined with an AWS SSM post patching task that utilizes the exit code (or startup script with email output) to identify failed services. 


#services that have been identified to be normal to be both "Automatic" and "Stopped" on an AWS EC2 instance
$ignore = @('edgeupdate','gupdate','Intel(R) TPM Provisioning Service','MapsBroker', 'sppsvc', 'stisvc')


start-sleep -seconds 150 # give DelayedAutostart services some time to start. May need to be increased for heavier services on slower servers (such as Exchange or SQL Services)

if ((get-service | where {$_.StartType -eq "Automatic" -and $_.Status -eq "Stopped"} | where {$_.Name -NotIn $ignore}).count -gt 0)
{
write-host "Uh-oh, a service might be having an issue!"
write-host "The following automatic services are stopped:"
get-service | where {$_.StartType -eq "Automatic" -and $_.Status -eq "Stopped"} | where {$_.Name -NotIn $ignore}
exit 1
}
else
{
write-host "Services are good!"
}

