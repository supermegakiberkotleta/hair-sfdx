public class SendOpportunityUpdateJob implements Queueable, Database.AllowsCallouts {
    private String oppId;
    private String leadId;
    private String reportFileLink;

    public SendOpportunityUpdateJob(String oppId, String leadId, String reportFileLink) {
        this.oppId = oppId;
        this.leadId = leadId;
        this.reportFileLink = reportFileLink;
    }

    public void execute(QueueableContext context) {
        try {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://lenderpro.itprofit.net/api/v1/opportunity-update');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(60000);

            // String token = EncodingUtil.base64Encode(Blob.valueOf('itprofit:itprofititprofit'));
            // req.setHeader('Authorization', 'Basic ' + token);

            Map<String, String> payload = new Map<String, String>{
                'opportunityId' => oppId,
                'leadId' => leadId,
                'reportFileLink' => reportFileLink
            };

            req.setBody(JSON.serialize(payload, true));

            HttpResponse res = http.send(req);
            System.debug('Response: ' + res.getStatusCode() + ' | ' + res.getBody());
        } catch (Exception e) {
            System.debug('Callout failed: ' + e.getMessage());
        }
    }
}