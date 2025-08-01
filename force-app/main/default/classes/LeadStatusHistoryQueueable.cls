public class LeadStatusHistoryQueueable implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> leadIdsToProcess;
    private Map<Id, String> leadIdToNewStatus;
    private Boolean isInsert;
    
    public LeadStatusHistoryQueueable(Set<Id> leadIds, Map<Id, String> statusMap, Boolean isInsertOperation) {
        this.leadIdsToProcess = leadIds;
        this.leadIdToNewStatus = statusMap;
        this.isInsert = isInsertOperation;
    }
    
    public void execute(QueueableContext context) {
        try {
            processLeadStatusHistory();
        } catch (Exception e) {
            System.debug('Error in LeadStatusHistoryQueueable: ' + e.getMessage());
            // Можно добавить логирование ошибок в отдельную таблицу
        }
    }
    
    private void processLeadStatusHistory() {
        List<Lead_Status_History__c> historyToInsert = new List<Lead_Status_History__c>();
        Map<Id, Lead_Status_History__c> leadToNewHistory = new Map<Id, Lead_Status_History__c>();
        
        if (isInsert) {
            // Для новых лидов создаем записи истории
            for (Id leadId : leadIdsToProcess) {
                String status = leadIdToNewStatus.get(leadId);
                if (String.isNotBlank(status)) {
                    Lead_Status_History__c newHistory = new Lead_Status_History__c(
                        Lead__c = leadId,
                        Status__c = status,
                        Date__c = System.now()
                    );
                    historyToInsert.add(newHistory);
                    leadToNewHistory.put(leadId, newHistory);
                }
            }
        } else {
            // Для обновлений проверяем существующие записи
            Map<String, Id> existingPairs = new Map<String, Id>();
            
            // Один запрос для получения всех существующих записей
            List<Lead_Status_History__c> existingHistory = [
                SELECT Id, Lead__c, Status__c
                FROM Lead_Status_History__c
                WHERE Lead__c IN :leadIdsToProcess
                AND Status__c IN :leadIdToNewStatus.values()
            ];
            
            for (Lead_Status_History__c h : existingHistory) {
                String key = h.Lead__c + ':' + h.Status__c;
                existingPairs.put(key, h.Id);
            }
            
            // Создаем новые записи только для уникальных комбинаций
            for (Id leadId : leadIdsToProcess) {
                String status = leadIdToNewStatus.get(leadId);
                if (String.isNotBlank(status)) {
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
        
        // Вставляем новые записи истории
        if (!historyToInsert.isEmpty()) {
            insert historyToInsert;
            
            // Обрабатываем первую запись и обновляем поле Status_History__c
            processFirstHistoryAndStatusField(leadToNewHistory.keySet());
        }
    }
    
    private void processFirstHistoryAndStatusField(Set<Id> affectedLeadIds) {
        // Обновляем Is_First_History__c для первой записи каждого лида
        updateFirstHistoryFlag(affectedLeadIds);
        
        // Обновляем поле Status_History__c на Lead
        updateLeadStatusHistoryField(affectedLeadIds);
    }
    
    private void updateFirstHistoryFlag(Set<Id> leadIds) {
        // Получаем минимальные даты для каждого лида
        Map<Id, Datetime> leadToMinDate = new Map<Id, Datetime>();
        for (AggregateResult ar : [
            SELECT Lead__c leadId, MIN(Date__c) minDate
            FROM Lead_Status_History__c
            WHERE Lead__c IN :leadIds
            GROUP BY Lead__c
        ]) {
            leadToMinDate.put((Id)ar.get('leadId'), (Datetime)ar.get('minDate'));
        }
        
        if (leadToMinDate.isEmpty()) return;
        
        // Получаем записи с минимальными датами
        List<Lead_Status_History__c> potentialFirstRecords = [
            SELECT Id, Lead__c, Date__c, Is_First_History__c
            FROM Lead_Status_History__c
            WHERE Lead__c IN :leadToMinDate.keySet()
            AND Date__c IN :leadToMinDate.values()
        ];
        
        List<Lead_Status_History__c> toUpdate = new List<Lead_Status_History__c>();
        
        for (Lead_Status_History__c record : potentialFirstRecords) {
            if (leadToMinDate.containsKey(record.Lead__c) &&
                record.Date__c == leadToMinDate.get(record.Lead__c) &&
                !record.Is_First_History__c) {
                record.Is_First_History__c = true;
                toUpdate.add(record);
            }
        }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    
    private void updateLeadStatusHistoryField(Set<Id> leadIds) {
        // Получаем всю историю статусов для лидов
        Map<Id, List<Lead_Status_History__c>> historyByLead = new Map<Id, List<Lead_Status_History__c>>();
        
        for (Lead_Status_History__c record : [
            SELECT Lead__c, Status__c, Date__c
            FROM Lead_Status_History__c
            WHERE Lead__c IN :leadIds
            ORDER BY Date__c ASC
        ]) {
            if (!historyByLead.containsKey(record.Lead__c)) {
                historyByLead.put(record.Lead__c, new List<Lead_Status_History__c>());
            }
            historyByLead.get(record.Lead__c).add(record);
        }
        
        // Получаем текущие лиды
        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>(
            [SELECT Id, Status_History__c, IsConverted FROM Lead WHERE Id IN :leadIds]
        );
        
        List<Lead> updates = new List<Lead>();
        
        for (Id leadId : historyByLead.keySet()) {
            List<Lead_Status_History__c> historyList = historyByLead.get(leadId);
            List<String> lines = new List<String>();
            
            for (Lead_Status_History__c h : historyList) {
                if (String.isNotBlank(h.Status__c) && h.Date__c != null) {
                    lines.add(h.Status__c + ' (' + h.Date__c.format() + ')');
                }
            }
            
            String newValue = String.join(lines, '\n');
            Lead existingLead = leadsToUpdate.get(leadId);
            
            // Проверяем, что лид не конвертирован и значение изменилось
            if (existingLead != null && !existingLead.IsConverted && newValue != existingLead.Status_History__c) {
                updates.add(new Lead(Id = leadId, Status_History__c = newValue));
            }
        }
        
        if (!updates.isEmpty()) {
            update updates;
        }
    }
} 