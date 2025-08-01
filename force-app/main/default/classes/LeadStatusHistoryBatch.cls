global class LeadStatusHistoryBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    global String query;
    global Integer processedRecords = 0;
    global Integer errorCount = 0;
    
    global LeadStatusHistoryBatch() {
        this.query = 'SELECT Id, Status FROM Lead WHERE IsConverted = false AND Status != null';
    }
    
    global LeadStatusHistoryBatch(String customQuery) {
        this.query = customQuery;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Lead> scope) {
        try {
            Set<Id> leadIds = new Set<Id>();
            Map<Id, String> leadIdToStatus = new Map<Id, String>();
            
            for (Lead l : scope) {
                if (String.isNotBlank(l.Status)) {
                    leadIds.add(l.Id);
                    leadIdToStatus.put(l.Id, l.Status);
                }
            }
            
            if (!leadIds.isEmpty()) {
                // Проверяем существующие записи истории
                Map<String, Id> existingPairs = new Map<String, Id>();
                List<Lead_Status_History__c> existingHistory = [
                    SELECT Id, Lead__c, Status__c
                    FROM Lead_Status_History__c
                    WHERE Lead__c IN :leadIds
                ];
                
                for (Lead_Status_History__c h : existingHistory) {
                    String key = h.Lead__c + ':' + h.Status__c;
                    existingPairs.put(key, h.Id);
                }
                
                // Создаем новые записи истории
                List<Lead_Status_History__c> historyToInsert = new List<Lead_Status_History__c>();
                
                for (Id leadId : leadIds) {
                    String status = leadIdToStatus.get(leadId);
                    String key = leadId + ':' + status;
                    
                    if (!existingPairs.containsKey(key)) {
                        Lead_Status_History__c newHistory = new Lead_Status_History__c(
                            Lead__c = leadId,
                            Status__c = status,
                            Date__c = System.now()
                        );
                        historyToInsert.add(newHistory);
                    }
                }
                
                if (!historyToInsert.isEmpty()) {
                    insert historyToInsert;
                    processedRecords += historyToInsert.size();
                }
                
                // Обновляем поле Status_History__c для обработанных лидов
                updateLeadStatusHistoryField(leadIds);
            }
            
        } catch (Exception e) {
            errorCount++;
            System.debug('Error in LeadStatusHistoryBatch execute: ' + e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        System.debug('LeadStatusHistoryBatch completed. Processed: ' + processedRecords + ', Errors: ' + errorCount);
        
        // Можно отправить email уведомление или записать в логи
        if (errorCount > 0) {
            System.debug('Batch completed with ' + errorCount + ' errors');
        }
    }
    
    private void updateLeadStatusHistoryField(Set<Id> leadIds) {
        try {
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
                
                if (existingLead != null && !existingLead.IsConverted && newValue != existingLead.Status_History__c) {
                    updates.add(new Lead(Id = leadId, Status_History__c = newValue));
                }
            }
            
            if (!updates.isEmpty()) {
                update updates;
            }
            
        } catch (Exception e) {
            System.debug('Error updating Status_History__c field: ' + e.getMessage());
        }
    }
    
    // Метод для запуска batch из кода
    public static void startBatch() {
        LeadStatusHistoryBatch batch = new LeadStatusHistoryBatch();
        Database.executeBatch(batch, 200); // Размер батча 200 записей
    }
    
    // Метод для запуска batch с кастомным запросом
    public static void startBatch(String customQuery) {
        LeadStatusHistoryBatch batch = new LeadStatusHistoryBatch(customQuery);
        Database.executeBatch(batch, 200);
    }
} 