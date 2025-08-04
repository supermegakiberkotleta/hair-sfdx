public with sharing class OnloanSecondController {

    @AuraEnabled(cacheable = false)
    public static void sendLeadToOnloan(String leadId) {
        System.debug('>>> Вызван метод sendLeadToOnloan с leadId: ' + leadId);

        if (String.isBlank(leadId)) {
            throw new AuraHandledException('Lead ID не может быть пустым');
        }

        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://lenderpro.ai/api/v1/webhook/re-send-ocrolus');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');

            Map<String, String> body = new Map<String, String>();
            body.put('leadId', leadId);
            String requestBody = JSON.serialize(body);
            request.setBody(requestBody);

            System.debug('>>> Отправка запроса на endpoint: ' + request.getEndpoint());
            System.debug('>>> Тело запроса: ' + requestBody);

            HttpResponse response = http.send(request);

            System.debug('>>> Код ответа: ' + response.getStatusCode());
            System.debug('>>> Тело ответа: ' + response.getBody());

            if (response.getStatusCode() != 200) {
                throw new AuraHandledException('Ошибка API: ' + response.getStatusCode() + ' — ' + response.getBody());
            }

        } catch (Exception ex) {
            System.debug('>>> Произошло исключение: ' + ex.getMessage());
            throw new AuraHandledException('Произошла ошибка: ' + ex.getMessage());
        }
    }
}