using namespace System.Net

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