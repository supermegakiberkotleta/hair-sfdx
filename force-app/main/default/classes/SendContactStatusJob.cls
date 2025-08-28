// File: force-app/main/default/classes/SendContactStatusJob.cls
public class SendContactStatusJob implements Queueable, Database.AllowsCallouts {
    private List<Contact> contactList;

    public SendContactStatusJob(List<Contact> contacts) {
        this.contactList = contacts;
    }

    public void execute(QueueableContext context) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://lenderpro.ai/api/v1/contact-status');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        List<Map<String, Object>> payloads = new List<Map<String, Object>>();
        for (Contact c : contactList) {
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('contact_id', c.Id);
            payload.put('contact_data', JSON.deserializeUntyped(JSON.serialize(c, true)));
            payloads.add(payload);
        }

        request.setBody(JSON.serialize(payloads, true));

        try {
            HttpResponse response = http.send(request);
            System.debug('Webhook response for Contact: ' + response.getStatusCode() + ' | ' + response.getBody());
        } catch (Exception ex) {
            System.debug('Failed to send webhook for Contact: ' + ex.getMessage());
        }
    }
}