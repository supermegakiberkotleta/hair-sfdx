public class CreateLeadTriggerHandler {
    @future(callout = true)
    public static void sendLeadDataToExternalService(String payload) {
        List<Object> leadList = (List<Object>) JSON.deserializeUntyped(payload);

        Boolean hasApprovedStatus = false;

        for (Object obj : leadList) {
            Map<String, Object> lead = (Map<String, Object>) obj;
            String status = (String) lead.get('Status');

            if (status == 'RISK ANALYSIS' || status == 'APPROVED') {
                hasApprovedStatus = true;
                break;
            }
        }

        if (hasApprovedStatus) {
            sendHttpRequest('https://79c3750f34c1.ngrok-free.app/api/salesforce/webhook', payload);
            sendHttpRequest('https://833f-185-76-9-35.ngrok-free.app/api/salesforce/webhook', payload);
            sendHttpRequest('https://loan24-3zsza.ondigitalocean.app/api/salesforce/webhook', payload);
        } else {
            sendHttpRequest('https://lenderpro.itprofit.net/api/v1/salesforce/webhook/updated', payload);
            sendHttpRequest('https://lenderpro.ai/api/v1/salesforce/webhook/updated', payload);
        }
    }

    private static void sendHttpRequest(String endpoint, String payload) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);

        Http http = new Http();

        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() != 200 && res.getStatusCode() != 201) {
                System.debug('Ошибка при отправке на ' + endpoint + ': ' + res.getStatusCode() + ' ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Исключение при отправке на ' + endpoint + ': ' + e.getMessage());
        }
    }
}