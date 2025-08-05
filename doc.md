## Create resource group
```bash
az group create --name Onaxsys-test-RG --location eastus
```

## Create resources from bicep file
```shell
az deployment group create --resource-group Onaxsys-test-RG --name main --template-file main.bicep
```

## Delete resource group along with all resources
```bash
az group delete --name onaxsys-test-rg --yes --no-wait
```

- --name: specifies the resource group.
- --yes: skips confirmation prompt.
- --no-wait: returns immediately without waiting for the operation to finish
