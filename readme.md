# Storm/Norce Event Compatibility Kit
The Event Compatibility Kit is infrastructure (using Azure) and a function to make HTTP Events from Norce Commerce
backwards compatible with the Storm Commerce way of delivering events through an Azure Service Bus.

The purpose is to make migrations from Storm Commerce to Norce Commerce with less effort and risk as well as being
a simple template for how to consume HTTP Events from Norce Commerce.

## What it does
Events from Norce Commerce is delivered through HTTP Events to an Azure Function (`HttpEventReceiver`) and sends
the http event to correct topics in an Azure Service Bus. Each topic have a subscription which can be used to
consume messages the exact same way as in Storm Commerce.

## Design philosophy
The Event Compatibility Kit is designed to be very simple, understandable, risk-free and cost-efficient option. Therefore, it's
been designed with a slightly lower security than what can be achieved in Azure. For example, the Service Bus is a
public Service Bus (for lower cost) and the Azure function connects to the Service Bus using a Shared Access
Policy/Connection String instead of using Managed Identities (to avoid that the user running the terraform code
doesn't need User Administration or Owner permissions).

The Service Bus is designed with one topic per event type and one subscription per topic. This approach is chosen to
allow different credentials (Shared Access Policies) for individual topics, depending on solution partner and/or
external parties connecting to the service bus. The initial setup includes a general Shared Access Policy for the
provided Azure function with `Send` permissions and Shared Access Policy with `Read` permissions which can be used in
your code (it's only for convenience).

## What it contains
### Infrastructure-as-code
A set of Terraform code to set up the infrastructure required:
- A Service Bus
- Topics required
- Subscriptions on each of the topics
- Shared Access Policies for the Azure function (sender) and your code (receiver).

### Azure function
An Azure Function (node.js) which is used to receive HTTP Events from Norce Commerce and transmitting those HTTP
Events to the ServiceBus which 

## Installation
- For Terraform see [Terraform Install](./terraform/readme.md).
- For Azure Function see [Azure Function Install](./function/readme.md)

## Usage
To use the solution, go to the azure function created in the Azure Portal and click the `HttpEventReceiver`
function, then click "Get Function Url" and copy the URL.

Go into Norce Commerce Admin and click Integrations &rarr; Events &rarr; and select the event you to be triggered.
For more information on how to [Configure Norce Commerce](https://docs.norce.io/developer-portal/system-integration/using-norceevent/)
see documentation.

> **_NOTE:_**  
Use the Function Url as *Http Event Delivery Url* _and_ and a http header `x-norce-event-type` with 
> the name of the event as value in one word, such as "CustomerChangedNotification".
> 
> You can also use a query parameter by appending `&norceEventType=CustomerChangedNotification` to the Function Url.
