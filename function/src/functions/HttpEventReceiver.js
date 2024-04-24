const {app} = require('@azure/functions');
const {ServiceBusClient} = require("@azure/service-bus");
const eventTypes = require("./types");

const errorMessage = (status, message) => {
    return {
        status: status,
        body: JSON.stringify({
            status: status,
            message: message
        }),
        headers: {
            'Content-Type': 'application/json'
        }
    }
}
app.http('HttpEventReceiver', {
    methods: ['POST'],
    authLevel: 'function',
    handler: async (request, context) => {

        let eventType = request.headers.get("x-norce-event-type") || request.query.get("norceEventType");
        if (!eventType) {
            return errorMessage(400, "Missing event type");
        }
        eventType = eventType.toLowerCase();
        if (!eventTypes.includes(eventType)) {
            return errorMessage(400, "Invalid event type");
        }

        if (!process.env.SERVICEBUSCONNSTR_sb_connection_string) {
            return errorMessage(500, "Connection string to Azure ServiceBus is missing");
        }

        try {
            let body = await request.json();
            const sbClient = new ServiceBusClient(process.env.SERVICEBUSCONNSTR_sb_connection_string);
            const sender = sbClient.createSender(eventType);
            await sender.sendMessages({
                applicationProperties: {
                    norceEventType: eventType,
                    ClientId: body.ClientId
                },
                body, contentType: "application/json"
            });
        } catch (e) {
            context.error(e.message, e.stack, e)
            return {
                status: 500,
                body: JSON.stringify({
                    status: 500,
                    message: e.message,
                }),
                headers: {
                    'Content-Type': 'application/json'
                }
            }
        }
    }
});

