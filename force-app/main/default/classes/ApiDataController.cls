public with sharing class ApiDataController {

    @AuraEnabled
    public static void updateDataFromApi(String dateStart, String dateFinish, String lender) {
        updateDataFromApiAsync(dateStart, dateFinish, lender);
    }

    @future(callout=true)
    public static void updateDataFromApiAsync(String dateStart, String dateFinish, String lender) {
        try {
            Map<String, Object> requestPayload = new Map<String, Object>{
                'date_start' => dateStart,
                'date_finish' => dateFinish,
                'lender' => lender
            };

            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setEndpoint('https://lenderpro.ai/api/v1/report/us-report-sf');
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setBody(JSON.serialize(requestPayload));
            httpRequest.setTimeout(120000);

            Http httpClient = new Http();
            HttpResponse httpResponse = httpClient.send(httpRequest);

            if (httpResponse.getStatusCode() != 200) {
                System.debug('API Error: ' + httpResponse.getBody());
                return;
            }

            // ✅ Десериализация ответа (того самого "parsed")
            Object parsed = JSON.deserializeUntyped(httpResponse.getBody());

            // Основная цель (как было)
            List<API_Data__c> recordsToInsert = new List<API_Data__c>();
            Map<String, API_Data__c> uniqueRecords = new Map<String, API_Data__c>();

            // Доп. цель: таблицы №3 и №4 → во второй объект
            List<API_Data2__c> recordsToInsert2 = new List<API_Data2__c>();
            Map<String, API_Data2__c> uniqueRecords2 = new Map<String, API_Data2__c>();

            // Осторожно: если записей много — лучше удалять батчами или через Batch Apex
            delete [SELECT Id FROM API_Data__c];
            delete [SELECT Id FROM API_Data2__c];

            if (parsed instanceof List<Object>) {
                List<Object> groups = (List<Object>) parsed;

                Integer globalTableIndex = 0; // 0=первая, 1=вторая, 2=третья, 3=четвёртая ...

                for (Object groupObj : groups) {
                    if (!(groupObj instanceof List<Object>)) continue;
                    List<Object> tableGroup = (List<Object>) groupObj;

                    for (Integer tableIndex = 0; tableIndex < tableGroup.size(); tableIndex++) {
                        Object tableObj = tableGroup[tableIndex];
                        if (!(tableObj instanceof List<Object>)) {
                            // не таблица — пропускаем без инкремента (счётчик двигаем только для валидных таблиц)
                            continue;
                        }

                        List<Object> table = (List<Object>) tableObj;
                        if (table.isEmpty()) {
                            // пустую таблицу считаем как занятый слот, чтобы не сбить глобальную нумерацию
                            globalTableIndex++;
                            continue;
                        }

                        // Заголовки + тип ряда
                        List<Object> headers = (List<Object>) table[0];
                        String rowType = (tableIndex == 0) ? 'SUM' : 'PERCENT';

                        // Строки данных
                        for (Integer rowIndex = 1; rowIndex < table.size(); rowIndex++) {
                            Object rowObj = table[rowIndex];
                            if (!(rowObj instanceof List<Object>)) continue;
                            List<Object> row = (List<Object>) rowObj;
                            if (row.isEmpty() || row[0] == null) continue;

                            // ---- API_Data__c (как раньше) ----
                            String uniqueKey = String.valueOf(row[0]) + '_' + rowType;
                            if (!uniqueRecords.containsKey(uniqueKey)) {
                                API_Data__c rec = new API_Data__c();
                                rec.Row_Type__c = rowType;

                                Integer maxCols = Math.min(row.size(), headers.size());
                                for (Integer colIndex = 0; colIndex < maxCols && colIndex <= 16; colIndex++) {
                                    String value = String.valueOf(row[colIndex]);
                                    if (colIndex == 0) rec.Column_1__c = value;
                                    else if (colIndex == 1) rec.Column_2__c = value;
                                    else if (colIndex == 2) rec.Column_3__c = value;
                                    else if (colIndex == 3) rec.Column_4__c = value;
                                    else if (colIndex == 4) rec.Column_5__c = value;
                                    else if (colIndex == 5) rec.Column_6__c = value;
                                    else if (colIndex == 6) rec.Column_7__c = value;
                                    else if (colIndex == 7) rec.Column_8__c = value;
                                    else if (colIndex == 8) rec.Column_9__c = value;
                                    else if (colIndex == 9) rec.Column_10__c = value;
                                    else if (colIndex == 10) rec.Column_11__c = value;
                                    else if (colIndex == 11) rec.Column_12__c = value;
                                    else if (colIndex == 12) rec.Column_13__c = value;
                                    else if (colIndex == 13) rec.Column_14__c = value;
                                    else if (colIndex == 14) rec.Column_15__c = value;
                                    else if (colIndex == 15) rec.Column_16__c = value;
                                    else if (colIndex == 16) rec.Column_17__c = value;
                                }
                                uniqueRecords.put(uniqueKey, rec);
                            }

                            // ---- API_Data2__c: только глобальные таблицы №3 и №4 ----
                            if (globalTableIndex == 2 || globalTableIndex == 3) {
                                String uniqueKey2 = String.valueOf(row[0]) + '_' + rowType;
                                if (!uniqueRecords2.containsKey(uniqueKey2)) {
                                    API_Data2__c rec2 = new API_Data2__c();
                                    rec2.Row_Type__c = rowType;

                                    Integer maxCols2 = Math.min(row.size(), headers.size());
                                    for (Integer colIndex2 = 0; colIndex2 < maxCols2 && colIndex2 <= 16; colIndex2++) {
                                        String value2 = String.valueOf(row[colIndex2]);
                                        if (colIndex2 == 0) rec2.Column_1__c = value2;
                                        else if (colIndex2 == 1) rec2.Column_2__c = value2;
                                        else if (colIndex2 == 2) rec2.Column_3__c = value2;
                                        else if (colIndex2 == 3) rec2.Column_4__c = value2;
                                        else if (colIndex2 == 4) rec2.Column_5__c = value2;
                                        else if (colIndex2 == 5) rec2.Column_6__c = value2;
                                        else if (colIndex2 == 6) rec2.Column_7__c = value2;
                                        else if (colIndex2 == 7) rec2.Column_8__c = value2;
                                        else if (colIndex2 == 8) rec2.Column_9__c = value2;
                                        else if (colIndex2 == 9) rec2.Column_10__c = value2;
                                        else if (colIndex2 == 10) rec2.Column_11__c = value2;
                                        else if (colIndex2 == 11) rec2.Column_12__c = value2;
                                        else if (colIndex2 == 12) rec2.Column_13__c = value2;
                                        else if (colIndex2 == 13) rec2.Column_14__c = value2;
                                        else if (colIndex2 == 14) rec2.Column_15__c = value2;
                                        else if (colIndex2 == 15) rec2.Column_16__c = value2;
                                        else if (colIndex2 == 16) rec2.Column_17__c = value2;
                                    }
                                    uniqueRecords2.put(uniqueKey2, rec2);
                                }
                            }
                        }

                        // таблица обработана — двигаем глобальный индекс
                        globalTableIndex++;
                    }
                }

                // Вставки
                recordsToInsert.addAll(uniqueRecords.values());
                if (!recordsToInsert.isEmpty()) insert recordsToInsert;

                recordsToInsert2.addAll(uniqueRecords2.values());
                if (!recordsToInsert2.isEmpty()) insert recordsToInsert2;
            }

        } catch (Exception e) {
            System.debug('Async Error: ' + e.getMessage());
            // здесь можно логировать в кастомный объект
        }
    }
}