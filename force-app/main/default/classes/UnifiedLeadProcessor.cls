public class UnifiedLeadProcessor implements Queueable, Database.AllowsCallouts {
    
    private Set<Id> leadIdsToProcess;
    private Map<Id, String> leadIdToNewStatus;
    private List<Map<String, Object>> changedLeadsForWebhook;
    private Boolean isInsert;
    
    public UnifiedLeadProcessor(Set<Id> leadIds, Map<Id, String> statusMap, List<Map<String, Object>> webhookData, Boolean isInsertOperation) {
        this.leadIdsToProcess = leadIds;
        this.leadIdToNewStatus = statusMap;
        this.changedLeadsForWebhook = webhookData;
        this.isInsert = isInsertOperation;
    }
    
    public void execute(QueueableContext context) {
        try {
            // 1. Обрабатываем историю статусов лидов
            if (!leadIdsToProcess.isEmpty()) {
                processLeadStatusHistory();
            }
            
            // 2. Отправляем webhook с изменениями
            if (changedLeadsForWebhook != null && !changedLeadsForWebhook.isEmpty()) {
                sendWebhookUpdate();
            }
            
        } catch (Exception e) {
            System.debug('Error in UnifiedLeadProcessor: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
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
            // Для обновлений создаем записи истории только для изменившихся статусов
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
            if (!record.Is_First_History__c) {
                record.Is_First_History__c = true;
                toUpdate.add(record);
            }
        }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    
    private void updateLeadStatusHistoryField(Set<Id> leadIds) {
        // Получаем все записи истории для лидов, отсортированные по дате
        List<Lead_Status_History__c> allHistory = [
            SELECT Lead__c, Status__c, Date__c
            FROM Lead_Status_History__c
            WHERE Lead__c IN :leadIds
            ORDER BY Lead__c, Date__c ASC
        ];
        
        // Группируем по лидам
        Map<Id, List<Lead_Status_History__c>> historyByLead = new Map<Id, List<Lead_Status_History__c>>();
        for (Lead_Status_History__c h : allHistory) {
            if (!historyByLead.containsKey(h.Lead__c)) {
                historyByLead.put(h.Lead__c, new List<Lead_Status_History__c>());
            }
            historyByLead.get(h.Lead__c).add(h);
        }
        
        // Получаем текущие лиды для проверки IsConverted
        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>([
            SELECT Id, IsConverted, Status_History__c
            FROM Lead
            WHERE Id IN :leadIds
        ]);
        
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
    
    private void sendWebhookUpdate() {
        if (changedLeadsForWebhook.isEmpty()) return;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://lenderpro.ai/api/v1/webhook/lead-update');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(changedLeadsForWebhook));
        req.setTimeout(30000); // 30 секунд таймаут
        
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('Webhook response: ' + res.getBody());
        } catch (Exception e) {
            System.debug('Webhook error: ' + e.getMessage());
        }
    }
}