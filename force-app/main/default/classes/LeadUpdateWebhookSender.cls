public with sharing class LeadUpdateWebhookSender implements Queueable, Database.AllowsCallouts {
    private List<Map<String, Object>> changedLeads;

    public LeadUpdateWebhookSender(List<Map<String, Object>> changedLeads) {
        this.changedLeads = changedLeads;
    }

    public void execute(QueueableContext context) {
        if (changedLeads.isEmpty()) return;
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://lenderpro.ai/api/v1/webhook/lead-update');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(changedLeads));
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Webhook response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Webhook error: ' + e.getMessage());
        }
    }
}