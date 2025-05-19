trigger TrackLeadStatus on Lead (after insert, after update) {
    List<Lead_Status_History__c> historyToInsert = new List<Lead_Status_History__c>();
    Map<Id, Lead_Status_History__c> leadToNewHistory = new Map<Id, Lead_Status_History__c>();

    Set<Id> leadIdsToCheckStatus = new Set<Id>();
    Map<Id, String> leadIdToNewStatus = new Map<Id, String>();

    if (Trigger.isInsert) {
        for (Lead newLead : Trigger.new) {
            Lead_Status_History__c newHistory = new Lead_Status_History__c(
                Lead__c = newLead.Id,
                Status__c = newLead.Status,
                Date__c = System.now()
            );
            historyToInsert.add(newHistory);
            leadToNewHistory.put(newLead.Id, newHistory);
        }
    }

    if (Trigger.isUpdate) {
        for (Lead newLead : Trigger.new) {
            Lead oldLead = Trigger.oldMap.get(newLead.Id);

            if (newLead.Status != oldLead.Status) {
                leadIdsToCheckStatus.add(newLead.Id);
                leadIdToNewStatus.put(newLead.Id, newLead.Status);
            }
        }

        // Один запрос, получаем все записи по LeadId + Status
        Map<String, Id> existingPairs = new Map<String, Id>();
        if (!leadIdsToCheckStatus.isEmpty()) {
            List<Lead_Status_History__c> existingHistory = [
                SELECT Id, Lead__c, Status__c
                FROM Lead_Status_History__c
                WHERE Lead__c IN :leadIdsToCheckStatus
                AND Status__c IN :leadIdToNewStatus.values()
            ];

            for (Lead_Status_History__c h : existingHistory) {
                String key = h.Lead__c + ':' + h.Status__c;
                existingPairs.put(key, h.Id);
            }

            for (Id leadId : leadIdsToCheckStatus) {
                String status = leadIdToNewStatus.get(leadId);
                String key = leadId + ':' + status;
                if (!existingPairs.containsKey(key)) {
                    Lead_Status_History__c newHistory = new Lead_Status_History__c(
                        Lead__c = leadId,
                        Status__c = status,
                        Date__c = System.now()
                    );
                    historyToInsert.add(newHistory);
                    leadToNewHistory.put(leadId, newHistory);
                }
            }
        }
    }

    if (!historyToInsert.isEmpty()) {
        insert historyToInsert;

        // Обработка "первая запись" — bulk-safe
        Set<Id> affectedLeadIds = leadToNewHistory.keySet();

        // Получаем минимальные Date__c по лидам
        Map<Id, Datetime> leadToMinDate = new Map<Id, Datetime>();
        for (AggregateResult ar : [
            SELECT Lead__c leadId, MIN(Date__c) minDate
            FROM Lead_Status_History__c
            WHERE Lead__c IN :affectedLeadIds
            GROUP BY Lead__c
        ]) {
            leadToMinDate.put((Id)ar.get('leadId'), (Datetime)ar.get('minDate'));
        }

        // Получаем записи с минимальными Date__c
        List<Lead_Status_History__c> potentialFirstRecords = [
            SELECT Id, Lead__c, Date__c
            FROM Lead_Status_History__c
            WHERE Lead__c IN :leadToMinDate.keySet()
            AND Date__c IN :leadToMinDate.values()
        ];

        Map<Id, Id> firstHistoryIds = new Map<Id, Id>();
        for (Lead_Status_History__c record : potentialFirstRecords) {
            if (leadToMinDate.containsKey(record.Lead__c) &&
                record.Date__c == leadToMinDate.get(record.Lead__c)) {
                firstHistoryIds.put(record.Lead__c, record.Id);
            }
        }


        // Обновим только нужные записи
        List<Lead_Status_History__c> toUpdate = [
            SELECT Id, Is_First_History__c
            FROM Lead_Status_History__c
            WHERE Id IN :firstHistoryIds.values()
        ];

        for (Lead_Status_History__c h : toUpdate) {
            h.Is_First_History__c = true;
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}
