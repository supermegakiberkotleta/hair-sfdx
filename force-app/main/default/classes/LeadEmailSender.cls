public class LeadEmailSender {

    @future(callout = true)
    public static void sendRejectionEmail(Id leadId, String name, String status) {
        System.debug('sendRejectionEmail вызван с параметрами: leadId=' + leadId + ', name=' + name + ', status=' + status);
        sendHttpPost(
            'https://lenderpro.ai/api/v1/email/send-rejection',
            leadId,
            name,
            status
        );
    }

    @future(callout = true)
    public static void sendOfferEmail(Id leadId, String name, String status) {
        System.debug('sendOfferEmail вызван с параметрами: leadId=' + leadId + ', name=' + name + ', status=' + status);
        sendHttpPost(
            'https://lenderpro.ai/api/v1/email/send-offer',
            leadId,
            name,
            status
        );
    }

    @future(callout = true)
    public static void sendOpportunityCreatedEmail(
        Id opportunityId,
        String opportunityName,
        Id leadId,
        String leadName
    ) {
        System.debug('sendOpportunityCreatedEmail вызван с параметрами: ');
        System.debug('opportunityId=' + opportunityId + ', opportunityName=' + opportunityName);
        System.debug('leadId=' + leadId + ', leadName=' + leadName);

        Map<String, Object> payload = new Map<String, Object> {
            'opportunityId' => opportunityId,
            'opportunityName' => opportunityName,
            'leadId' => leadId,
            'leadName' => leadName
        };

        sendHttpPost(
            'https://lenderpro.stoliarov.itprofit.net/api/v1/webhook/send-opportunity-created',
            payload
        );
    }

    private static void sendHttpPost(String endpoint, Map<String, Object> payload) {
        System.debug('Отправляем HTTP POST на endpoint: ' + endpoint);
        System.debug('Данные запроса: ' + JSON.serialize(payload));

        HttpRequest req = new HttpRequest();
        Http http = new Http();

        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        req.setBody(JSON.serialize(payload));

        try {
            HttpResponse res = http.send(req);
            System.debug('HTTP-ответ получен. Код статуса: ' + res.getStatusCode());
            System.debug('Тело ответа: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Ошибка при HTTP-вызове: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }

    // Поддержка старых методов через отдельные параметры
    private static void sendHttpPost(String endpoint, Id id, String name, String status) {
        Map<String, Object> payload = new Map<String, Object> {
            'id' => id,
            'name' => name,
            'status' => status
        };
        sendHttpPost(endpoint, payload);
    }
}