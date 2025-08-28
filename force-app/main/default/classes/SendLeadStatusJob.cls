public class SendLeadStatusJob implements Queueable, Database.AllowsCallouts {
    private Lead leadRecord;

    public SendLeadStatusJob(Lead leadRecord) {
        this.leadRecord = leadRecord;
    }

    public void execute(QueueableContext context) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://lenderpro.ai/api/v1/lead-status');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>();
        payload.put('lead_id', leadRecord.Id);
        payload.put('status', leadRecord.Status);
        payload.put('lead_data', JSON.deserializeUntyped(JSON.serialize(leadRecord, true)));

        request.setBody(JSON.serialize(payload, true)); // Сериализуем всё, включая null

        try {
            HttpResponse response = http.send(request);
            System.debug('Webhook response: ' + response.getBody());
        } catch (Exception ex) {
            System.debug('Failed to send webhook: ' + ex.getMessage());
        }
    }
}