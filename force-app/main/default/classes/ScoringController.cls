public with sharing class ScoringController {
    @AuraEnabled
    public static Map<String,Object> runBacklogScoring() {
        // 1) Берём лидов
        List<Lead> leads = [
            SELECT Id, uuid__c, EIN__c, Loan_Start_Date__c
            FROM Lead
            WHERE uuid__c != NULL AND EIN__c != NULL
        ];

        // 2) Собираем payload
        List<Map<String,Object>> leadItems = new List<Map<String,Object>>();
        for (Lead leadItem : leads) {
            leadItems.add(new Map<String,Object>{
                'id' => leadItem.Id,
                'uuid' => leadItem.uuid__c,
                'ein' => leadItem.EIN__c,
                'start_credit_date' => leadItem.Loan_Start_Date__c
            });
        }

        Map<String,Object> payload = new Map<String,Object>{
            'leads' => leadItems
        };

        // 3) Готовим POST-запрос
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setEndpoint('https://lenderpro.itprofit.net/api/v1/scoring-parser');

        httpRequest.setMethod('POST');
        httpRequest.setHeader('Content-Type','application/json');
        httpRequest.setBody(JSON.serialize(payload));
        httpRequest.setTimeout(120000);

        // 4) Отправляем
        Http httpClient = new Http();
        HttpResponse httpResponse = httpClient.send(httpRequest);

        return new Map<String,Object>{
            'statusCode' => httpResponse.getStatusCode(),
            'responseBody' => httpResponse.getBody(),
            'sentPayload' => payload
        };
    }
}