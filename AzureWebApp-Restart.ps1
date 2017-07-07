<#
.SYNOPSIS
    Invokes a restart of an Azure Web App if the Application Insights Availability Test reports that the site is down.
.DESCRIPTION
    Uses Azure RM PowerShell to execute a PowerShell Workflow.
    The script will perform an Invoke-WebRequest against the site to verify that it is indeed down and not an Application Insights issue.

    If the site is confirmed as being down then the Web Application will be restarted.
    Application Insights WebHooks do not accept parameter passing, therefore, the Web App name must be incorporated into the workflow.

.NOTES
    Author:  Richard J Green
    Version: 0.1
    Date:    7th July 2017
.LINK
    https://www.richardjgreen.net
.EXAMPLE
    No example required. The script runs silently as an Azure Automation Runbook.
#>

workflow AzureWebApp-Restart{

    # Get the current timestamp first
    $timestamp = Get-Date -Format "dd/MM/yyyy HH:MM:ss z"

    # Setup the Parameters for Execution
    $subscriptionId = "Your-Subscription-GUID"
    $uri = "https://company.com"
    $resourceGroupName = "Your-Resource-Group-Name"
    $webAppName = "Your-Azure-Web-App-Name"
    $azureConnectionAssetName = "AzureRunAsConnection"

    # Stamp the Automation Job  with the name of the WebHook and the invokation date and time stamp.
    Write-Output "Invoked by WebHook at $timestamp GMT."

    # Check that the site is actually down and that it's not an Azure Application Insights Issue.
    $statusCode = (Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec 120).StatusCode

    # Error Handling: Throw error if the site is actually up
    If ($statusCode -eq "200") {
        Write-Error "The site returned a HTTP 200 OK status code which means the site is actually online."
        Exit
    } Else {
        Write-Output "The site returned a $statusCode status code therefore the site is down."
    }
   
    # Get the Automation Credential and Connect to Azure AD
    $cred = Get-AutomationConnection -Name $azureConnectionAssetName

    # Error Handling: Missing or invalid Connection input.
    If (!($cred)) {
        Write-Error "There is no Connection Asset in the Azure Automation account for $azureConnectionAssetName. Check the Connection Name that was supplied."
        Exit
    }

    # Login to the Azure Subscription using the Service Principal account.
    Try {
        Add-AzureRmAccount -ServicePrincipal -ApplicationId $cred.ApplicationId -CertificateThumbprint $cred.CertificateThumbprint -TenantId $cred.TenantId -ErrorAction Stop -SubscriptionId $subscriptionId
    } Catch {
        # Error Handling: Invalid Service Principal Login
        Write-Error "The Connection Asset provided was unable to login. Check that the connection has not expired or has not been invalidated."
        Exit
    }

    # Validation: Validate that the Resource Group is accessible.
    If ($resourceGroupName -ne "") {
        $resourceGroupCheck = Get-AzureRmResourceGroup -Name $resourceGroupName
        If ($resourceGroupCheck) {
            Write-Output "Validated Resource Group $resourceGroupName successfully."
        } Else {
            Write-Error "The Resource Group name $resourceGroupName is either not accessible or does not exist. Check the Resource Group name that was provided."
            Exit
        }
    }

    # Validation: Validate that the Web App is accessible.
    If ($webAppName -ne "") {
        $webAppCheck = Get-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $webAppName
        If ($webAppCheck) {
            Write-Output "Validated Web App $webAppName successfully."
        } Else {
            Write-Error "The Web App name $webAppName is either not accessible or does not exist. Check the Web App name that was provided."
            Exit
        }
    } 

    # Output the names of the VMs that will be effected.
    Write-Output "The Web App $webAppName will be restarted. This will cause the site to become unresponsive for a period of time."

    # Restart the Web App
    Restart-AzureRmWebApp -ResourceGroupName $resourceGroupName -Name $webAppName
    
    # Stamp the log for completion.        
    $timestamp = Get-Date -Format "dd/MM/yyyy HH:MM:ss z"
    Write-Output "Completed at $timestamp GMT."

}
