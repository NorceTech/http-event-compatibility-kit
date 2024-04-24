# HTTP Event Delivery Receiver
This is a very simple azure function for receiving events from Norce Commerce and sending to an Azure
Service Bus to become backwards compatible with Storm Commerce Event transport using Azure Service Bus.

## Installation
To install the azure function, run the following commands in the `function` directory.
See Terraform for description of customer slug.
```shell
> npm install
> func azure functionapp publish func-snecck-<customerslug>
```