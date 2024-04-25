# HTTP Event Delivery Receiver
This is a very simple azure function for receiving events from Norce Commerce and sending to an Azure
Service Bus to become backwards compatible with Storm Commerce Event transport using Azure Service Bus.

## Installation
To install the azure function, run the following commands in the `function` directory.
See Terraform for description of customer slug.
```shell
> npm install
> func azure functionapp publish func-snceck-<customerslug>
```

You can of course set up a CD pipeline, which normally is recommended, but we don't expect this code to change 
to any extent so if you want to continue using this code we recommend that you push it to a repo of your own
(or fork this repo) and continue from there.