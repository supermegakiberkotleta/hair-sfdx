public with sharing class ApiDataController {
    @AuraEnabled
    public static void updateDataFromApi(String dateStart, String dateFinish, String lender) {
        try {
            Map<String, Object> params = new Map<String, Object>{
                'date_start' => dateStart,
                'date_finish' => dateFinish,
                'lender' => lender
            };

            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://lenderpro.ai/api/v1/us-report-sf'); 
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(params));

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                throw new AuraHandledException('Ошибка API: ' + res.getStatusCode() + ' ' + res.getBody());
            }

            Object parsed = JSON.deserializeUntyped(res.getBody());
            List<API_Data__c> recordsToInsert = new List<API_Data__c>();

            if (parsed instanceof List<Object>) {
                List<Object> topLevel = (List<Object>) parsed;

                for (Object groupData : topLevel) {
                    if (!(groupData instanceof List<Object>)) continue;
                    List<Object> groupList = (List<Object>) groupData;

                    for (Object tableObj : groupList) {
                        if (!(tableObj instanceof List<Object>)) continue;
                        List<Object> table = (List<Object>) tableObj;

                        // Пропускаем заголовки (table[0]), обрабатываем остальные строки
                        for (Integer i = 1; i < table.size(); i++) {
                            List<Object> row = (List<Object>) table[i];

                            API_Data__c record = new API_Data__c();
                            if (row.size() > 0) record.Column_1__c = String.valueOf(row[0]); // Date
                            if (row.size() > 1) record.Column_2__c = String.valueOf(row[1]); // Loans number
                            if (row.size() > 2) record.Column_3__c = String.valueOf(row[2]); // Amount
                            if (row.size() > 3) record.Column_4__c = String.valueOf(row[3]); // Fee
                            if (row.size() > 4) record.Column_5__c = String.valueOf(row[4]);
                            if (row.size() > 5) record.Column_6__c = String.valueOf(row[5]);
                            if (row.size() > 6) record.Column_7__c = String.valueOf(row[6]);
                            if (row.size() > 7) record.Column_8__c = String.valueOf(row[7]);
                            if (row.size() > 8) record.Column_9__c = String.valueOf(row[8]);

                            recordsToInsert.add(record);
                        }
                    }
                }
            }

            // Очистить старые записи
            delete [SELECT Id FROM API_Data__c];

            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }

        } catch (Exception e) {
            throw new AuraHandledException('Ошибка при вызове API: ' + e.getMessage());
        }
    }
}