public with sharing class LeadStatusService {

    @AuraEnabled(cacheable=true)
    public static List<Map<String,Object>> getLeadStatusDurations(Id leadId) {
        // Получаем все записи истории статусов для лида
        List<Lead_Status_History__c> histories = [
            SELECT Status__c, Date__c
            FROM Lead_Status_History__c
            WHERE Lead__c = :leadId
            ORDER BY Date__c ASC
        ];

        List<Map<String,Object>> result = new List<Map<String,Object>>();

        for (Integer i = 0; i < histories.size(); i++) {
            Lead_Status_History__c current = histories[i];
            Datetime enteredDate = current.Date__c;
            Datetime exitedDate;

            if (i < histories.size() - 1) {
                exitedDate = histories[i+1].Date__c;
            } else {
                exitedDate = System.now(); // если последняя запись, текущая дата
            }

            // Разница в миллисекундах
            Long diffMillis = exitedDate.getTime() - enteredDate.getTime();

            // Переводим в минуты и часы
            Long durationMinutes = diffMillis / (1000 * 60); // общее количество минут
            Long durationHours = diffMillis / (1000 * 60 * 60); // общее количество часов
            Double durationDays = durationHours / 24.0;

            result.add(new Map<String,Object>{
                'Status' => current.Status__c,
                'EnteredDate' => enteredDate,
                'ExitedDate' => exitedDate,
                'DurationHours' => durationHours,
                'DurationMinutes' => durationMinutes, // ← ДОБАВЛЕНО
                'DurationDays' => durationDays
            });
        }

        return result;
    }
}