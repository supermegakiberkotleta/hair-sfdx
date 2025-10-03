public with sharing class ApiLeadStageController {

    @AuraEnabled
    public static void updateLeadStageReport(String dateStart, String dateFinish) {
        // Запускаем асинхронно, чтобы не держать долгую транзакцию UI
        updateLeadStageReportAsync(dateStart, dateFinish);
    }

    @future
    public static void updateLeadStageReportAsync(String dateStart, String dateFinish) {
        try {
            // 1) Парсим даты в границы интервала
            Date startDate = Date.valueOf(dateStart);
            Date finishDate = Date.valueOf(dateFinish);
            Datetime intervalStart = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
            Datetime intervalEnd = Datetime.newInstance(finishDate, Time.newInstance(23, 59, 59, 999));

            // 2) Жёсткий порядок статусов -> соответствие колонкам Column_1__c..Column_18__c
            List<String> orderedStatuses = new List<String>{
                'NEW APPLICATION',
                'RISK ANALYSIS',
                'STOP-FACTORS CHECK',
                'APPROVED',
                'DENIED',
                'MANUAL PARSING',
                'Final Denied',
                'Offer sent to broker',
                'Offer sent to broker manual',
                'Offer Accepted',
                'Agreement sent',
                'Agreement signed',
                'Funding call',
                'final check Mary',
                'Final check Violetta',
                'To pay',
                'Call after',
                'Closed Lost'
            };

            // 3) Берём все лиды
            List<Lead> leads = [
                SELECT Id
                FROM Lead
            ];
            if (leads.isEmpty()) {
                // Чистим и пишем пустой отчёт
                deleteExistingLeadStageReport();
                insert buildLeadStageRecordWithAverages(new Map<String, String>(), orderedStatuses);
                return;
            }

            Set<Id> leadIds = new Set<Id>();
            for (Lead ld : leads) leadIds.add(ld.Id);

            // 4) Тянем всю историю статусов для этих лидов одной выборкой
            List<Lead_Status_History__c> allHistories = [
                SELECT Lead__c, Status__c, Date__c
                FROM Lead_Status_History__c
                WHERE Lead__c IN :leadIds
                ORDER BY Lead__c ASC, Date__c ASC
            ];
            if (allHistories.isEmpty()) {
                deleteExistingLeadStageReport();
                insert buildLeadStageRecordWithAverages(new Map<String, String>(), orderedStatuses);
                return;
            }

            // 5) Группируем истории по лиду
            Map<Id, List<Lead_Status_History__c>> historiesByLead = new Map<Id, List<Lead_Status_History__c>>();
            for (Lead_Status_History__c h : allHistories) {
                if (!historiesByLead.containsKey(h.Lead__c)) {
                    historiesByLead.put(h.Lead__c, new List<Lead_Status_History__c>());
                }
                historiesByLead.get(h.Lead__c).add(h);
            }

            // 6) Копим минуты по статусам для лидов, прошедших фильтр NEW APPLICATION в интервале
            Map<String, Long> totalMinutesByStatus = new Map<String, Long>();
            Map<String, Integer> countsByStatus = new Map<String, Integer>();
            for (String s : orderedStatuses) {
                totalMinutesByStatus.put(s, 0L);
                countsByStatus.put(s, 0);
            }

            Datetime nowPoint = System.now();

            for (Id leadId : historiesByLead.keySet()) {
                List<Lead_Status_History__c> leadHist = historiesByLead.get(leadId);
                if (leadHist == null || leadHist.isEmpty()) continue;

                // Строим «интервалы» как в LeadStatusService: для каждой записи датой выхода будет следующая дата, а для последней — System.now()
                List<Map<String, Object>> intervals = new List<Map<String, Object>>();
                for (Integer i = 0; i < leadHist.size(); i++) {
                    Lead_Status_History__c current = leadHist[i];
                    Datetime enteredDate = current.Date__c;
                    Datetime exitedDate = (i < leadHist.size() - 1) ? leadHist[i + 1].Date__c : nowPoint;

                    Long diffMillis = exitedDate.getTime() - enteredDate.getTime();
                    Long durationMinutes = diffMillis / (1000L * 60L);

                    Map<String, Object> intervalInfo = new Map<String, Object>();
                    intervalInfo.put('Status', current.Status__c);
                    intervalInfo.put('EnteredDate', enteredDate);
                    intervalInfo.put('ExitedDate', exitedDate);
                    intervalInfo.put('DurationMinutes', durationMinutes);
                    intervals.add(intervalInfo);
                }

                // Фильтр: берём лид только если в нём есть статус NEW APPLICATION с EnteredDate в заданном интервале
                Boolean includeLead = false;
                for (Map<String, Object> interval : intervals) {
                    String st = (String)interval.get('Status');
                    Datetime entered = (Datetime)interval.get('EnteredDate');
                    if (st == 'NEW APPLICATION' && entered != null && entered >= intervalStart && entered <= intervalEnd) {
                        includeLead = true;
                        break;
                    }
                }
                if (!includeLead) continue;

                // Агрегируем минуты по статусам только для лидов, прошедших фильтр
                for (Map<String, Object> interval : intervals) {
                    String st = (String)interval.get('Status');
                    if (st == null) continue;
                    if (!totalMinutesByStatus.containsKey(st)) continue; // игнор статусов вне списка

                    Long mins = (Long)interval.get('DurationMinutes');
                    if (mins == null) mins = 0L;

                    totalMinutesByStatus.put(st, totalMinutesByStatus.get(st) + mins);
                    countsByStatus.put(st, countsByStatus.get(st) + 1);
                }
            }

            // 7) Считаем средние и форматируем h:mm
            Map<String, String> averagesFormatted = new Map<String, String>();
            for (String st : orderedStatuses) {
                Long totalMins = totalMinutesByStatus.get(st);
                Integer cnt = countsByStatus.get(st);
                if (cnt == null || cnt == 0 || totalMins == null) {
                    averagesFormatted.put(st, '0:00');
                } else {
                    Long avgMins = totalMins / cnt;
                    averagesFormatted.put(st, formatMinutesToHourMinute(avgMins));
                }
            }

            // 8) Чистим предыдущие строки отчёта и пишем одну запись
            deleteExistingLeadStageReport();
            API_Lead_Stage__c recordToInsert = buildLeadStageRecordWithAverages(averagesFormatted, orderedStatuses);
            insert recordToInsert;

        } catch (Exception e) {
            System.debug('updateLeadStageReportAsync error: ' + e.getMessage());
        }
    }

    // Удаляем все предыдущие записи отчёта
    private static void deleteExistingLeadStageReport() {
        List<API_Lead_Stage__c> existing = [SELECT Id FROM API_Lead_Stage__c];
        if (!existing.isEmpty()) {
            delete existing;
        }
    }

    // Формируем одну запись API_Lead_Stage__c, кладём значения в Column_1__c..Column_18__c по порядку статусов
    private static API_Lead_Stage__c buildLeadStageRecordWithAverages(Map<String, String> averagesFormatted, List<String> orderedStatuses) {
        API_Lead_Stage__c rec = new API_Lead_Stage__c();

        for (Integer i = 0; i < orderedStatuses.size(); i++) {
            String statusName = orderedStatuses[i];
            String value = averagesFormatted != null && averagesFormatted.containsKey(statusName) ? String.valueOf(averagesFormatted.get(statusName)) : '0:00';

            // i = 0..17 -> Column_1__c..Column_18__c
            switch on i {
                when 0 { rec.Column_1__c = value; }
                when 1 { rec.Column_2__c = value; }
                when 2 { rec.Column_3__c = value; }
                when 3 { rec.Column_4__c = value; }
                when 4 { rec.Column_5__c = value; }
                when 5 { rec.Column_6__c = value; }
                when 6 { rec.Column_7__c = value; }
                when 7 { rec.Column_8__c = value; }
                when 8 { rec.Column_9__c = value; }
                when 9 { rec.Column_10__c = value; }
                when 10 { rec.Column_11__c = value; }
                when 11 { rec.Column_12__c = value; }
                when 12 { rec.Column_13__c = value; }
                when 13 { rec.Column_14__c = value; }
                when 14 { rec.Column_15__c = value; }
                when 15 { rec.Column_16__c = value; }
                when 16 { rec.Column_17__c = value; }
                when 17 { rec.Column_18__c = value; }
            }
        }

        return rec;
    }

    // Форматирование минут в h:mm (без ведущих нулей у часов, с ведущим нулём у минут)
    private static String formatMinutesToHourMinute(Long totalMinutes) {
        if (totalMinutes == null || totalMinutes < 0) totalMinutes = 0;
        Long hours = totalMinutes / 60;
        Long minutes = totalMinutes - (hours * 60);
        String minutesStr = (minutes < 10) ? ('0' + String.valueOf(minutes)) : String.valueOf(minutes);
        return String.valueOf(hours) + ':' + minutesStr;
    }
}