public with sharing class ApiOpportunityStageController {

    @AuraEnabled
    public static void updateOpportunityStageReport(String dateStart, String dateFinish, String lender) {
        updateOpportunityStageReportAsync(dateStart, dateFinish, lender);
    }

    @future(callout=true)
    public static void updateOpportunityStageReportAsync(String dateStart, String dateFinish, String lender) {
        try {
            // 1) Подготавливаем запрос
            Map<String, Object> payload = new Map<String, Object>{
                'date_start' => dateStart,
                'date_finish' => dateFinish,
                'lender' => lender
            };

            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://lenderpro.ai/api/v1/report/opportunity-stage');
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(JSON.serialize(payload));
            request.setTimeout(120000);

            Http http = new Http();
            HttpResponse response = http.send(request);

            if (response.getStatusCode() != 200) {
                System.debug('API error: ' + response.getStatusCode() + ' → ' + response.getBody());
                return;
            }

            // 2) Парсим ответ
            Object parsed = JSON.deserializeUntyped(response.getBody());
            if (!(parsed instanceof Map<String, Object>)) {
                System.debug('Unexpected JSON format');
                return;
            }

            Map<String, Object> root = (Map<String, Object>) parsed;

            Map<String, Object> transitionsMap = (Map<String, Object>) root.get('transitions');
            Map<String, Object> returnsMap = (Map<String, Object>) root.get('returns');

            if (transitionsMap == null && returnsMap == null) {
                System.debug('No data in JSON');
                return;
            }

            // 3) Очищаем старые записи и вставляем две новые
            delete [SELECT Id FROM API_Opportunity_Stage__c];

            List<API_Opportunity_Stage__c> recordsToInsert = new List<API_Opportunity_Stage__c>();

            if (transitionsMap != null) {
                recordsToInsert.add(buildStageRecord('Transitions', transitionsMap));
            }
            if (returnsMap != null) {
                recordsToInsert.add(buildStageRecord('Returns', returnsMap));
            }

            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }

        } catch (Exception e) {
            System.debug('Async error: ' + e.getMessage());
        }
    }

    private static API_Opportunity_Stage__c buildStageRecord(String rowType, Map<String, Object> dataMap) {
        API_Opportunity_Stage__c record = new API_Opportunity_Stage__c();
        record.Column_1__c = rowType; // Picklist: Transitions / Returns

        record.Column_2__c = toInteger(dataMap.get('0 days'));
        record.Column_3__c = toInteger(dataMap.get('1-5 days'));
        record.Column_4__c = toInteger(dataMap.get('6-10 days'));
        record.Column_5__c = toInteger(dataMap.get('11-15 days'));
        record.Column_6__c = toInteger(dataMap.get('16-30 days'));

        return record;
    }

    private static Integer toInteger(Object value) {
        if (value == null) return null;
        try {
            return Integer.valueOf(String.valueOf(value));
        } catch (Exception e) {
            System.debug('Cannot convert to Integer: ' + value);
            return null;
        }
    }
}