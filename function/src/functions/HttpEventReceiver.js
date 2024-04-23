const { app } = require('@azure/functions');

app.http('HttpEventReceiver', {
    methods: ['GET', 'POST'],
    authLevel: 'anonymous',
    handler: async (request, context) => {
        console.log(`Http function processed request for url "${request.url}"`);
        let body = await request.text();
        console.log("body", body)
        console.log("x-norce-event-type", request.headers.get("x-norce-event-type"));
        // const name = request.query.get('name') || await request.text() || 'world';

        return { body: `Hello, boy!` };
    }
});
