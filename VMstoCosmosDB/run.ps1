using namespace System.Net
<#
.SYNOPSIS
    This function collects running virtual machines and stores them in a Cosmos DB.
.DESCRIPTION
    The VMs that are currently running are collected from the Azure subscription.
    A check is done if the VM already exists in the Cosmos DB.
    If not, it is added.
    A http response is send to confirm if the action succeeded.
.INPUTS
    HTTP Trigger
    Cosmos DB
.OUTPUTS
    Cosmos DB
    HTTP response
.NOTES
    This is part of an Azure Function App made to demonstrate the connection with Cosmos DB.
    Made by Barbara Forbes
    @Ba4bes
    4bes.nl
.LINK
    https://4bes.nl/2020/05/03/configure-azure-powershell-function-apps-with-cosmos-db/
#>

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata, $CosmosDBInput)
try {

    # Collect the VMs that are now runnting
    $RunningVMs = get-Azvm -Status | Where-Object { $_.PowerState -eq "VM running" }
    foreach ($RunningVM in $RunningVMs) {
        # An object is created to push to the database
        $Object = [PSCustomObject]@{
            id         = $RunningVM.Name
            vmName     = $RunningVM.Name
            PowerState = $RunningVM.PowerState
        }

        # Check if the VM is already present in the database
        if (($CosmosDBInput.id) -contains $Object.id) {
            Write-Output "$($Object.id) already exists in the database"
        }
        else {
            Push-OutputBinding -Name CosmosDBOutput -Value $Object
            Write-Output "$($Object.id) has been pushed to the Cosmos DB"
        }
    }
    # create a status and body to return
    $Status = [HttpStatusCode]::OK
    $Body = "VMs have been added to the cosmosDB"
}
Catch {
    $Status = [HttpStatusCode]::BadRequest
    $Body = "Something went wrong, could not add VMs"
}

# Give an http response to show if the push to database succeeded
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = $status
        Body       = $Body
    })