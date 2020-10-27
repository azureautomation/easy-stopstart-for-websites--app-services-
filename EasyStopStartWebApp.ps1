Workflow EasyStopStartWebApp 
{
	# Parameters
	Param(
		[Parameter (Mandatory= $true)]
	    [bool]$Stop,
		
		[Parameter (Mandatory= $true)]
		[string]$CredentialAssetName,

        [Parameter (Mandatory =$true)]
        [string]$WebAppName
	   )  
	   
	#The name of the Automation Credential Asset this runbook will use to authenticate to Azure.
    $CredentialAssetName = $CredentialAssetName;
	
	#Get the credential with the above name from the Automation Asset store
    $Cred = Get-AutomationPSCredential -Name $CredentialAssetName
    if(!$Cred) {
        Throw "Could not find an Automation Credential Asset named '${CredentialAssetName}'. Make sure you have created one in this Automation Account."
    }

    #Connect to your Azure Account   	
	Add-AzureRmAccount -Credential $Cred
	Add-AzureAccount -Credential $Cred
	
    #Check for each subscription to find WebApp  
    Get-AzureSubscription | ForEach-Object {
        Write-Output "`n Looking into $($_.SubscriptionName) subscription..."  
  
        #Select subscription  
        Select-AzureSubscription -SubscriptionId $_.SubscriptionId  
        Select-AzureRmSubscription -SubscriptionId $_.SubscriptionId  
	
		$status = 'Stopped'
		if ($Stop)
		{
			$status = 'Running'
		}

		# Get Running WebApps (Websites)
		$websites = Get-AzureWebsite | where-object -FilterScript{$_.state -eq $status -and $_.Name -eq $WebAppName}
		
		foreach -parallel ($website In $websites)
		{
			if ($Stop)
			{
				$result = Stop-AzureWebsite $website.Name
				if($result)
				{
					Write-Output "- $($website.Name) did not shutdown successfully"
				}
				else
				{
					Write-Output "+ $($website.Name) shutdown successfully"
				}
			}
			else
			{
				$result = Start-AzureWebsite $website.Name
				if($result)
				{
					Write-Output "- $($website.Name) did not start successfully"
				}
				else
				{
					Write-Output "+ $($website.Name) started successfully"
				}
			} 
		}
	}	
}