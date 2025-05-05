trigger TrackLeadStatus on Lead (after insert, after update) {
    List<Lead_Status_History__c> historyToInsert = new List<Lead_Status_History__c>();
    Map<Id, Lead_Status_History__c> leadToNewHistory = new Map<Id, Lead_Status_History__c>();

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
                List<Lead_Status_History__c> existingHistory = [
                    SELECT Id
                    FROM Lead_Status_History__c
                    WHERE Lead__c = :newLead.Id
                    AND Status__c = :newLead.Status
                    LIMIT 1
                ];

                if (existingHistory.isEmpty()) {
                    Lead_Status_History__c newHistory = new Lead_Status_History__c(
                        Lead__c = newLead.Id,
                        Status__c = newLead.Status,
                        Date__c = System.now()
                    );
                    historyToInsert.add(newHistory);
                    leadToNewHistory.put(newLead.Id, newHistory);
                }
            }
        }
    }

    if (!historyToInsert.isEmpty()) {
        insert historyToInsert;

        // Получаем ID лидов, для которых мы добавили записи
        Set<Id> affectedLeadIds = leadToNewHistory.keySet();

        // Получаем минимальные CreatedDate (первые записи) по лидам
        Map<Id, Id> firstHistoryIds = new Map<Id, Id>();
        for (AggregateResult ar : [
            SELECT Lead__c leadId, MIN(CreatedDate) minDate
            FROM Lead_Status_History__c
            WHERE Lead__c IN :affectedLeadIds
            GROUP BY Lead__c
        ]) {
            Id leadId = (Id)ar.get('leadId');
            Datetime minDate = (Datetime)ar.get('minDate');

            // Найдём соответствующую запись
            Lead_Status_History__c firstRecord = [
                SELECT Id
                FROM Lead_Status_History__c
                WHERE Lead__c = :leadId AND CreatedDate = :minDate
                LIMIT 1
            ];
            firstHistoryIds.put(leadId, firstRecord.Id);
        }

        // Обновим нужные записи
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
