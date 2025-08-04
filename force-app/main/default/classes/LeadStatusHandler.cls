public class LeadStatusHandler {

    @future(callout = true)
    public static void sendRejectionEmail(Id leadId, String name, String status) {
        System.debug('sendRejectionEmail вызван с параметрами: leadId=' + leadId + ', name=' + name + ', status=' + status);
        sendHttpPost('https://lenderpro.ai/api/v1/email/send-rejection', leadId, name, status);
    }

    @future(callout = true)
    public static void sendOfferEmail(Id leadId, String name, String status) {
        System.debug('sendOfferEmail вызван с параметрами: leadId=' + leadId + ', name=' + name + ', status=' + status);
        sendHttpPost('https://lenderpro.ai/api/v1/email/send-offer', leadId, name, status);
    }

    private static void sendHttpPost(String endpoint, Id leadId, String name, String status) {
        System.debug('Отправляем HTTP POST на endpoint: ' + endpoint);
        System.debug('Данные запроса: leadId=' + leadId + ', name=' + name + ', status=' + status);

        HttpRequest req = new HttpRequest();
        Http http = new Http();

        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>{
            'id' => leadId,
            'name' => name,
            'status' => status
        };

        String jsonBody = JSON.serialize(payload);
        req.setBody(jsonBody);
        System.debug('Тело запроса (JSON): ' + jsonBody);

        try {
            HttpResponse res = http.send(req);
            System.debug('HTTP-ответ получен. Код статуса: ' + res.getStatusCode());
            System.debug('Тело ответа: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Ошибка при HTTP-вызове: ' + e.getMessage() + ' | Детали: ' + e.getStackTraceString());
        }
    }
}