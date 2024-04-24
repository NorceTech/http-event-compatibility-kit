# Storm/Norce Event Compatibility Kit
The Event Compatibility Kit is infrastructure (using Azure) and a function to make HTTP Events from Norce Commerce
backwards compatible with the Storm way of delivering events through an Azure Service Bus.


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
provided Azure function with `Send` permissions and Shared Access Policy with reader permissions which can be used in
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
