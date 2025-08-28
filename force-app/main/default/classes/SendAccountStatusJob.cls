// File: force-app/main/default/classes/SendAccountStatusJob.cls
public class SendAccountStatusJob implements Queueable, Database.AllowsCallouts {
    private List<Account> accountList;

    public SendAccountStatusJob(List<Account> accounts) {
        this.accountList = accounts;
    }

    public void execute(QueueableContext context) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://lenderpro.ai/api/v1/account-status');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        List<Map<String, Object>> payloads = new List<Map<String, Object>>();
        for (Account acc : accountList) {
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('account_id', acc.Id);
            payload.put('account_data', JSON.deserializeUntyped(JSON.serialize(acc, true))); // Полная копия с null
            payloads.add(payload);
        }

        request.setBody(JSON.serialize(payloads, true)); // Отправляем массив

        try {
            HttpResponse response = http.send(request);
            System.debug('Webhook response for Account: ' + response.getStatusCode() + ' | ' + response.getBody());
        } catch (Exception ex) {
            System.debug('Failed to send webhook for Account: ' + ex.getMessage());
        }
    }
}