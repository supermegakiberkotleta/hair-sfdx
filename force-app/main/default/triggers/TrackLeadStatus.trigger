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

        Set<Id> affectedLeadIds = leadToNewHistory.keySet();

        // === Отметим первую запись как Is_First_History__c ===
        Map<Id, Datetime> leadToMinDate = new Map<Id, Datetime>();
        for (AggregateResult ar : [
            SELECT Lead__c leadId, MIN(Date__c) minDate
            FROM Lead_Status_History__c
            WHERE Lead__c IN :affectedLeadIds
            GROUP BY Lead__c
        ]) {
            leadToMinDate.put((Id)ar.get('leadId'), (Datetime)ar.get('minDate'));
        }

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

        // === Обновим поле Status_History__c на Lead ===

        Map<Id, List<Lead_Status_History__c>> historyByLead = new Map<Id, List<Lead_Status_History__c>>();

        for (Lead_Status_History__c record : [
            SELECT Lead__c, Status__c, Date__c
            FROM Lead_Status_History__c
            WHERE Lead__c IN :affectedLeadIds
            ORDER BY Date__c ASC
        ]) {
            if (!historyByLead.containsKey(record.Lead__c)) {
                historyByLead.put(record.Lead__c, new List<Lead_Status_History__c>());
            }
            historyByLead.get(record.Lead__c).add(record);
        }

        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>(
            [SELECT Id, Status_History__c, IsConverted FROM Lead WHERE Id IN :affectedLeadIds]
        );

        List<Lead> updates = new List<Lead>();

        for (Id leadId : historyByLead.keySet()) {
            List<Lead_Status_History__c> historyList = historyByLead.get(leadId);
            List<String> lines = new List<String>();

            for (Lead_Status_History__c h : historyList) {
                if (!String.isBlank(h.Status__c) && h.Date__c != null) {
                    lines.add(h.Status__c + ' (' + h.Date__c.format() + ')');
                }
            }

            String newValue = String.join(lines, '\n');
            Lead existingLead = leadsToUpdate.get(leadId);
            Object isConvertedRaw = existingLead.get('IsConverted');
            Boolean isConverted = (isConvertedRaw instanceof Boolean) ? (Boolean)isConvertedRaw : false;

            if (!isConverted && newValue != existingLead.Status_History__c) {
                updates.add(new Lead(Id = leadId, Status_History__c = newValue));
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
}
