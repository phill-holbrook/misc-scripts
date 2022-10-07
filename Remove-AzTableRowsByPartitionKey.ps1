<#
    .SYNOPSIS
    Deletes all rows in a provided Azure Table that belong to a provided Partition Key.

    .DESCRIPTION
    Deletes all rows in a provided Azure Table that belong to a provided Partition Key.

    .PARAMETER PartitionKeyArray
    Specifies the Partition Key(s) to which the rows belong.

    .PARAMETER Table
    The Azure Table object obtained via the Az.Storage module.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    If you haven't already, first connect to Azure with the Az.Accounts module:
    PS> Connect-AzAccount
    
    Then, get the table in question using the Az.Storage module:
    PS> $TableName = "myTable"
    PS> $ResourceGroupName = "myResourceGroup"
    PS> $StorageAccountName = "myStorageAccount"
    PS> $StorageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName
    PS> $Context = $StorageAccount.Context
    PS> $Table = (Get-AzStorageTable -Name $TableName -Context $Context).CloudTable

    Next, define your Partition Key(s):
    PS> $PartitionKeyArray = "myKey1", "myKey2"

    Finally, run this script:
    PS> .\Remove-AzTableRowsByPartitionKey.ps1 -PartitionKeyArray $PartitionKeyArray -Table $Table
#>

param(
    [string[]]$PartitionKeyArray,
    [Microsoft.Azure.Cosmos.Table.CloudTable]$Table
)

# Requires Az.Accounts, Az.Storage, and AzureRmStorageTable modules
Import-Module Az.Accounts
Import-Module Az.Storage
Import-Module AzureRmStorageTable

ForEach ($PartitionKey in $PartitionKeyArray){

    Write-Output "[$(get-date -f yyyyMMdd-HHmm)] - Preparing to remove all rows with PartitionKey $PartitionKey from Table $($Table.Name)."

    # Grab all rows from the partition key. Takes about a minute to grab 20,000 rows.
    $Rows = Get-AzTableRow -Table $Table -PartitionKey $PartitionKey

    If (-not $Rows){

        Write-Output "[$(get-date -f yyyyMMdd-HHmm)] - No rows found with PartitionKey $PartitionKey from Table $($Table.Name)."
        Continue

    }

    Write-Output "[$(get-date -f yyyyMMdd-HHmm)] - Found $($Rows.Count) rows. Beginning removal."

    # Build a list to store table entities.
    $List = [System.Collections.Generic.List[object]]::new()

    # Make a table entity for each row and add it to the list.
    ForEach ($Row in $Rows){
        $List.Add([Microsoft.Azure.Cosmos.Table.TableEntity]::new($Row.PartitionKey,$Row.RowKey))
    }

    while($list){

        # Make a batch operation object to store our operations.
        $batchOperation = New-Object Microsoft.Azure.Cosmos.Table.tableBatchOperation

        # Batch operations have a limit of 100 operations so we need to split the list up.
        if ($list.count -gt 100){$batch = $list[0..99]}
        else {$batch = $list[0..$list.count]}
        
        foreach($b in $batch){
            
            # The Delete operation requires the ETag be set to '*'
            $b.ETag = "*"

            # Create a table operation object for each table entity using the Delete option
            $TableOperation = [Microsoft.Azure.Cosmos.Table.TableOperation]::Delete($b)

            # Add the table operation to our batch
            $batchOperation.Add($TableOperation)

        }

        # Send the batch of operations to the table
        $Status = $Table.ExecuteBatch($batchOperation)
        If ($Status.HttpStatusCode -ne 204){
            Write-Warning "HTTP Status Code $($Status.HttpStatusCode) returned for batch operation on Partition Key $PartitionKey."
        }

        # Remove each batch item from the list
        $batch | ForEach-Object{$list.remove($_)} | Out-Null

        # null out these values to prepare for the next batch
        $batch = $null
        $batchOperation = $null
        $Status = $null

        # Once the list is empty, break the loop
        if ($list.count -eq 0){$list = $null}

    }

    Write-Output "[$(get-date -f yyyyMMdd-HHmm)] - Removed $($Rows.Count) rows."

    $Rows = $null

}