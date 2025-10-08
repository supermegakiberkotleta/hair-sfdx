public with sharing class OpportunityStatusController {
    @AuraEnabled
    public static void callUpdateStatus(Id opportunityId, String selectedStatus) {
        if (opportunityId == null) {
            throw new AuraHandledException('Не передан Opportunity Id');
        }

        Set<String> allowed = new Set<String>{'Performing','Collection'};
        if (String.isBlank(selectedStatus) || !allowed.contains(selectedStatus)) {
            throw new AuraHandledException('Некорректный статус');
        }

        Opportunity opportunityRecord = [
            SELECT Id, Lender_type__c, SlaesForceLeadId__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];

        String baseUrl = 'https://lenderpro.itprofit.net/api/v1/update-status';

        // Собираем параметры запроса
        List<String> queryParams = new List<String>();
        queryParams.add('status=' + EncodingUtil.urlEncode(selectedStatus, 'UTF-8'));
        if (String.valueOf(opportunityRecord.Lender_type__c) != null) {
            queryParams.add('lender=' + EncodingUtil.urlEncode(String.valueOf(opportunityRecord.Lender_type__c), 'UTF-8'));
        }
        if (String.valueOf(opportunityRecord.SlaesForceLeadId__c) != null) {
            queryParams.add('lead_id=' + EncodingUtil.urlEncode(String.valueOf(opportunityRecord.SlaesForceLeadId__c), 'UTF-8'));
        }

        String urlWithParams = baseUrl + '?' + String.join(queryParams, '&');

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod('GET');
        httpRequest.setEndpoint(urlWithParams);
        httpRequest.setTimeout(60000);

        Http httpClient = new Http();
        HttpResponse httpResponse = httpClient.send(httpRequest);

        Integer statusCode = httpResponse.getStatusCode();
        if (statusCode >= 400) {
            throw new AuraHandledException('Ошибка вызова API: ' + String.valueOf(statusCode) + ' ' + httpResponse.getStatus());
        }
    }
}