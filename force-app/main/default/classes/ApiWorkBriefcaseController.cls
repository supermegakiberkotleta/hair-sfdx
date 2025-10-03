public with sharing class ApiWorkBriefcaseController {

    @AuraEnabled
    public static void updateWorkBriefcaseReport(String dateStart, String dateFinish, String lender) {
        updateWorkBriefcaseReportAsync(dateStart, dateFinish, lender);
    }

    @future(callout=true)
    public static void updateWorkBriefcaseReportAsync(String dateStart, String dateFinish, String lender) {
        try {
            Map<String, Object> requestPayload = new Map<String, Object>{
                'date_start' => dateStart,
                'date_finish' => dateFinish,
                'lender' => lender
            };

            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setEndpoint('https://lenderpro.ai/api/v1/report/work-briefcase');
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setBody(JSON.serialize(requestPayload));
            httpRequest.setTimeout(120000);

            Http httpClient = new Http();
            HttpResponse httpResponse = httpClient.send(httpRequest);

            if (httpResponse.getStatusCode() != 200) {
                System.debug('API Error: ' + httpResponse.getStatusCode() + ' ' + httpResponse.getBody());
                return;
            }

            Object parsed = JSON.deserializeUntyped(httpResponse.getBody());

            // чистим предыдущие записи
            List<API_Work_Briefcase__c> existing = [SELECT Id FROM API_Work_Briefcase__c];
            if (!existing.isEmpty()) {
                delete existing;
            }

            List<API_Work_Briefcase__c> recordsToInsert = new List<API_Work_Briefcase__c>();

            if (parsed instanceof List<Object>) {
                addRowsFromTable(recordsToInsert, (List<Object>)parsed);
            }

            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }

        } catch (Exception e) {
            System.debug('Async Error in updateWorkBriefcaseReportAsync: ' + e.getMessage());
        }
    }

    /**
     * Преобразует «таблицу» (List<List<Object>>) в записи API_Work_Briefcase__c.
     */
    private static void addRowsFromTable(List<API_Work_Briefcase__c> target, List<Object> table) {
        if (table == null || table.isEmpty()) return;

        for (Object rowObj : table) {
            if (!(rowObj instanceof List<Object>)) continue;

            List<Object> row = (List<Object>)rowObj;
            if (row.isEmpty()) continue;

            API_Work_Briefcase__c record = new API_Work_Briefcase__c();
            Integer maxCols = Math.min(25, row.size());

            for (Integer i = 0; i < maxCols; i++) {
                String value = safeToString(row[i]);

                switch on i {
                    when 0 { record.Column_1__c = value; }
                    when 1 { record.Column_2__c = value; }
                    when 2 { record.Column_3__c = value; }
                    when 3 { record.Column_4__c = value; }
                    when 4 { record.Column_5__c = value; }
                    when 5 { record.Column_6__c = value; }
                    when 6 { record.Column_7__c = value; }
                    when 7 { record.Column_8__c = value; }
                    when 8 { record.Column_9__c = value; }
                    when 9 { record.Column_10__c = value; }
                    when 10 { record.Column_11__c = value; }
                    when 11 { record.Column_12__c = value; }
                    when 12 { record.Column_13__c = value; }
                    when 13 { record.Column_14__c = value; }
                    when 14 { record.Column_15__c = value; }
                    when 15 { record.Column_16__c = value; }
                    when 16 { record.Column_17__c = value; }
                }
            }

            target.add(record);
        }
    }

    private static String safeToString(Object value) {
        if (value == null) return null;
        return String.valueOf(value);
    }
}