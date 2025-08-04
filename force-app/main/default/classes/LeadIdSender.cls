public with sharing class LeadIdSender {
    
    @AuraEnabled
    public static String sendLeadIdToEndpoint(String leadId) {
        if (String.isBlank(leadId)) {
            throw new AuraHandledException('Lead ID не может быть пустым');
        }

        // Получаем данные лида для дополнительной информации
        Lead leadRecord;
        try {
            leadRecord = [SELECT Id, Name, Email, Phone, Company FROM Lead WHERE Id = :leadId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Лид с указанным ID не найден');
        }

        String endpointUrl = 'https://lenderpro.ai/api/v1/lead-generate-link'; // Замените на ваш эндпоинт

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(30000); // Таймаут 30 секунд

        // Подготавливаем данные для отправки
        Map<String, Object> payload = new Map<String, Object>{
            'leadId' => leadId,
            'leadName' => leadRecord.Name,
            'email' => leadRecord.Email,
            'phone' => leadRecord.Phone,
            'company' => leadRecord.Company,
            'timestamp' => Datetime.now().format('yyyy-MM-dd HH:mm:ss')
        };

        request.setBody(JSON.serialize(payload));

        HttpResponse response;
        try {
            response = http.send(request);
            System.debug('HTTP Response Status: ' + response.getStatusCode());
            System.debug('HTTP Response Body: ' + response.getBody());
        } catch (System.CalloutException e) {
            throw new AuraHandledException('Ошибка при вызове внешнего сервиса: ' + e.getMessage());
        }

        if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
            return 'ID лида успешно отправлен на эндпоинт. Статус: ' + response.getStatusCode();
        } else {
            throw new AuraHandledException('Ошибка сервера: ' + response.getStatusCode() + ' - ' + response.getBody());
        }
    }
}