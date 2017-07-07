# azure-automation-webapp-restart
Azure Automation Runbook to trigger an Azure Web App restart. Designed to be invoked by a webhook from another event such as Azure Application Insights detecting an outage.

This PowerShell script can be imported to an Azure Automation account as a PowerShell workflow. Once imported, the variable block at the head of the script must be configured with your environment details, including: Subscription ID, Resource Group Name, Web App Name, Azure Login credential.

Once the runbook is configured, a Webhook can be applied to the runbook. An Azure Application Insights account with an Availability Monitor can be configured to use the Webhook when an outage is detected. The webhook will trigger the runbook, in turn, triggering a restart of the Web App.

NOTE: Azure Application Insights does not accept input parameters when calling a webhook. It is for this reason that the Resource Group Name and Web App Name are coded into the runbook. If you have multiple Web Apps which you wish to apply this logic to, you will need to duplicate and operate multiple instances of the runbook.
