# Infrastructure installation
## Prerequisites 
- You need an Azure subscription where you want to install the infrastructure.
- Permission to create a service principal
- Azure-cli (recommended)

## Preparation
This guide assumes you're running Linux or MacOSX. 

Get the subscription ID from the Azure portal or from running `az login`

Set which subscription to use:
```shell
> az account set -s "<id>"
```

Create a Service Principal
```shell
> az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<id>"
```

The response from the command above results in a JSON response:
```json
{
  "appId": "b1d89de0-b233-42q9-dp40-629ce72f7b53",
  "displayName": "azure-cli-2024-04-23-07-39-35",
  "password": "AQm9R~XpaSm_jIgWjxHkp4wgLAlwpiynVPq._dNh",
  "tenant": "05355f7e-58a2-4228-9ae2-95095d23c936"
}
```
Use the response above to set the following environment variables
```shell
export ARM_CLIENT_ID="<appId>"
export ARM_CLIENT_SECRET="<password>"
export ARM_TENANT_ID="<tenant>"
export ARM_SUBSCRIPTION_ID="<subscription ID>"
```
# Installation
In the `terraform` directory, execute the following commands. The `customer_slug` variable must be set to ensure 
resources with globally unique name requirements will be created. Max 12 alphanumeric characters.
```shell
> terraform init
> terraform plan -var="customer_slug=<yourslug>"
```
And if everything looks good, apply the terraform code.
```shell
> terraform apply -var="customer_slug=<yourcorporation>"
```