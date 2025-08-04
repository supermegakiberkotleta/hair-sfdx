public class LeadStatusNotifierHelper {

    @future(callout = true)
    public static void sendHttpPost(String endpoint, Id leadId, String name, String status) {
        System.debug('Отправляем POST-запрос на: ' + endpoint);
        System.debug('Данные: Id=' + leadId + ', Name=' + name + ', Status=' + status);

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');

        Map<String, Object> payload = new Map<String, Object>{
            'id' => leadId,
            'name' => name,
            'status' => status
        };

        req.setBody(JSON.serialize(payload));

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Получен ответ. Код: ' + res.getStatusCode());
            System.debug('Тело: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Ошибка HTTP-вызова: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
}