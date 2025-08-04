public with sharing class GenerateReportController {
    @AuraEnabled
    public static String sendLeadId(String leadId) {
        if (String.isBlank(leadId)) {
            throw new AuraHandledException('Lead ID не может быть пустым');
        }

        String endpointUrl = 'https://lenderpro.ai/api/v1/generate-report';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(60000); // ⏱ Установлен таймаут в 60 секунд

        Map<String, String> bodyMap = new Map<String, String>{ 'leadId' => leadId };
        request.setBody(JSON.serialize(bodyMap));

        HttpResponse response;
        try {
            response = http.send(request);
        } catch (System.CalloutException e) {
            throw new AuraHandledException('Ошибка при вызове внешнего сервиса: ' + e.getMessage());
        }

        if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
            return 'Успех: ' + response.getBody();
        } else {
            throw new AuraHandledException('Ошибка: ' + response.getStatusCode() + ' - ' + response.getBody());
        }
    }

    @AuraEnabled
    public static String sendOpportunityId(String opportunityId) {
        if (String.isBlank(opportunityId)) {
            throw new AuraHandledException('Opportunity ID не может быть пустым');
        }

        String endpointUrl = 'https://lenderpro.ai/api/v1/generate-opportunity-report';

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpointUrl);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(60000); // ⏱ Установлен таймаут в 60 секунд

        Map<String, String> bodyMap = new Map<String, String>{ 'opportunityId' => opportunityId };
        request.setBody(JSON.serialize(bodyMap));

        HttpResponse response;
        try {
            response = http.send(request);
        } catch (System.CalloutException e) {
            throw new AuraHandledException('Ошибка при вызове внешнего сервиса: ' + e.getMessage());
        }

        if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
            return 'Успех: ' + response.getBody();
        } else {
            throw new AuraHandledException('Ошибка: ' + response.getStatusCode() + ' - ' + response.getBody());
        }
    }
}