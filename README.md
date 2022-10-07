# Miscellaneous Scripts

This repository contains random scripts I've written to accomplish random tasks. ***Use at your own risk.***

## Script List

- [Remove-AzTableRowsByPartitionKey.ps1](Remove-AzTableRowsByPartitionKey.ps1)
  - I had a need to delete several tens of thousands of rows from an Azure Table across multiple partition keys. Deleting rows individually would take far too long, and dropping the table entirely wasn't an option.
  - There currently isn't a PowerShell module that supports [Batch Operations](https://learn.microsoft.com/en-us/dotnet/api/microsoft.azure.cosmos.table.tablebatchoperation?view=azure-dotnet) so I had to write my own script that makes use of the Azure SDK provided with the Az PowerShell module.
  - Shout out to [Shinigami](https://blog.bitscry.com/author/shinigami/) for their excellent [blog post](https://blog.bitscry.com/2019/03/25/efficiently-deleting-rows-from-azure-table-storage/) that pointed me in the right direction.