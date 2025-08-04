public with sharing class OpportunityUpdateWebhookSender implements Queueable, Database.AllowsCallouts {
    private List<Opportunity> changedOpportunities;

    public OpportunityUpdateWebhookSender(List<Opportunity> changedOpportunities) {
        this.changedOpportunities = changedOpportunities;
    }

    public void execute(QueueableContext context) {
        if (changedOpportunities.isEmpty()) return;
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://lenderpro.ai/api/v1/webhook/lead-update');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(changedOpportunities));
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Webhook response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Webhook error: ' + e.getMessage());
        }
    }
}