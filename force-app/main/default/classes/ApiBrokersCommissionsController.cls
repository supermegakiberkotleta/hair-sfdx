public with sharing class ApiBrokersCommissionsController {

    @AuraEnabled
    public static void updateBrokersCommissionsReport(String lender) {
        updateBrokersCommissionsReportAsync(lender);
    }

    @future(callout=true)
    public static void updateBrokersCommissionsReportAsync(String lender) {
        try {
            // 1) Формируем запрос
            Map<String, Object> requestPayload = new Map<String, Object>{
                'lender' => lender
            };

            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setEndpoint('https://lenderpro.itprofit.net/api/v1/report/brokers-commissions');
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setBody(JSON.serialize(requestPayload));
            httpRequest.setTimeout(120000);

            // 2) Отправляем
            Http httpClient = new Http();
            HttpResponse httpResponse = httpClient.send(httpRequest);

            if (httpResponse.getStatusCode() != 200) {
                System.debug('API Error: ' + httpResponse.getStatusCode() + ' ' + httpResponse.getBody());
                return;
            }

            // 3) Десериализуем ответ
            Object parsed = JSON.deserializeUntyped(httpResponse.getBody());

            // 4) Чистим предыдущие записи (при необходимости можно заменить на upsert)
            List<API_Brokers_Commissions__c> existing = [SELECT Id FROM API_Brokers_Commissions__c];
            if (!existing.isEmpty()) {
                delete existing;
            }

            // 5) Преобразуем полученные данные в записи Salesforce
            List<API_Brokers_Commissions__c> recordsToInsert = new List<API_Brokers_Commissions__c>();

            // Формат 1: корень — это List<List<Object>>
            if (parsed instanceof List<Object>) {
                List<Object> table = (List<Object>) parsed;
                addRowsFromTable(recordsToInsert, table);
            }
            // Формат 2: корень — это Map с ключом "data" (или "table")
            else if (parsed instanceof Map<String, Object>) {
                Map<String, Object> root = (Map<String, Object>) parsed;

                if (root.containsKey('data') && root.get('data') instanceof List<Object>) {
                    addRowsFromTable(recordsToInsert, (List<Object>) root.get('data'));
                } else if (root.containsKey('table') && root.get('table') instanceof List<Object>) {
                    addRowsFromTable(recordsToInsert, (List<Object>) root.get('table'));
                } else {
                    // Попробуем найти любую List<List<Object>> глубже на один уровень
                    for (Object valueObj : root.values()) {
                        if (valueObj instanceof List<Object>) {
                            addRowsFromTable(recordsToInsert, (List<Object>) valueObj);
                        }
                    }
                }
            }

            // 6) Вставляем
            if (!recordsToInsert.isEmpty()) {
                insert recordsToInsert;
            }

        } catch (Exception e) {
            System.debug('Async Error in updateBrokersCommissionsReportAsync: ' + e.getMessage());
        }
    }

    /**
     * Добавляет строки в список записей API_Brokers_Commissions__c из «таблицы» (List<List<Object>>).
     * Ожидается, что каждая строка — это List<Object> с до 9 колонок.
     * Первая строка, если это заголовок, тоже будет записана; при необходимости фильтруйте вне метода.
     */
    private static void addRowsFromTable(List<API_Brokers_Commissions__c> target, List<Object> table) {
        if (table == null || table.isEmpty()) return;

        for (Object rowObj : table) {
            if (!(rowObj instanceof List<Object>)) continue;

            List<Object> row = (List<Object>) rowObj;
            if (row.isEmpty()) continue;

            API_Brokers_Commissions__c record = new API_Brokers_Commissions__c();

            Integer maxCols = Math.min(9, row.size());
            for (Integer i = 0; i < maxCols; i++) {
                String value = String.valueOf(row[i]);

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
                }
            }

            target.add(record);
        }
    }
}