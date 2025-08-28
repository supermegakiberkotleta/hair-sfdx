// File: SendOpportunityStatusJob.cls
public class SendOpportunityStatusJob implements Queueable, Database.AllowsCallouts {
    private List<Opportunity> opportunityList;

    public SendOpportunityStatusJob(List<Opportunity> opportunities) {
        this.opportunityList = opportunities;
    }

    public void execute(QueueableContext context) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://lenderpro.ai/api/v1/opportunity-status');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        // Подготавливаем payload
        List<Map<String, Object>> payloads = new List<Map<String, Object>>();
        for (Opportunity opp : opportunityList) {
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('opportunity_id', opp.Id);
            payload.put('stage', opp.StageName);
            payload.put('opportunity_data', JSON.deserializeUntyped(JSON.serialize(opp, true))); // Полная копия
            payloads.add(payload);
        }

        request.setBody(JSON.serialize(payloads, true)); // Отправляем массив, если нужно; или по одному

        try {
            HttpResponse response = http.send(request);
            System.debug('Webhook response for Opportunity: ' + response.getStatusCode() + ' | ' + response.getBody());
        } catch (Exception ex) {
            System.debug('Failed to send webhook for Opportunity: ' + ex.getMessage());
        }
    }
}