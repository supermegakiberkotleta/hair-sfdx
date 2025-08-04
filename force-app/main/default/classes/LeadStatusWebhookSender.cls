public class LeadStatusWebhookSender {
    
    private static final String PRIMARY_ENDPOINT = 'https://lenderpro.ai/api/v1/send-opportunity-created';
    private static final String SECONDARY_ENDPOINT = 'https://lenderpro.ai/api/v1/webhook/create-user'; // Замените на реальный URL
        
    @future(callout = true)
    public static void sendLeadStatusWebhook(Id leadId, String leadName) {
        System.debug('sendLeadStatusWebhook вызван с параметрами: leadId=' + leadId + ', leadName=' + leadName);
        
        Map<String, Object> payload = new Map<String, Object> {
            'leadId' => leadId,
            'leadName' => leadName
        };
        
        // Отправка на основной эндпоинт
        sendHttpPost(PRIMARY_ENDPOINT, payload);
        
        // Отправка на дополнительный эндпоинт
        sendHttpPost(SECONDARY_ENDPOINT, payload);
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
            
            if (res.getStatusCode() != 200) {
                System.debug('Предупреждение: Получен неожиданный код статуса: ' + res.getStatusCode());
            }
        } catch (Exception e) {
            System.debug('Ошибка при HTTP-вызове: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
    }
    
    
}