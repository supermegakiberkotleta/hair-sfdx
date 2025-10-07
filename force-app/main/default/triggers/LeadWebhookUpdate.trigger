trigger LeadWebhookUpdate on Lead (after insert, after update) {
    List<Map<String, Object>> changedLeads = new List<Map<String, Object>>();
    Set<Id> leadIdsToProcess = new Set<Id>();
    Map<Id, String> leadIdToNewStatus = new Map<Id, String>();

    for (Integer i = 0; i < Trigger.new.size(); i++) {
        Lead oldLead = Trigger.isUpdate ? Trigger.old[i] : null;
        Lead newLead = Trigger.new[i];
        
        // Собираем данные для webhook (только для обновлений)
        if (Trigger.isUpdate) {
            Map<String, Object> changedFields = new Map<String, Object>();
            for (String fieldName : Trigger.newMap.get(newLead.Id).getPopulatedFieldsAsMap().keySet()) {
                Object oldValue = oldLead.get(fieldName);
                Object newValue = newLead.get(fieldName);
                if (oldValue != newValue) {
                    changedFields.put(fieldName, newValue);
                }
            }
            if (!changedFields.isEmpty()) {
                changedFields.put('Id', newLead.Id);
                changedLeads.add(changedFields);
            }
        }
        
        // Собираем данные для отслеживания статусов
        if (Trigger.isInsert) {
            // Для новых лидов собираем все ID и статусы
            if (String.isNotBlank(newLead.Status)) {
                leadIdsToProcess.add(newLead.Id);
                leadIdToNewStatus.put(newLead.Id, newLead.Status);
            }
        } else if (Trigger.isUpdate) {
            // Для обновлений собираем только те лиды, у которых изменился статус
            if (newLead.Status != oldLead.Status && String.isNotBlank(newLead.Status)) {
                leadIdsToProcess.add(newLead.Id);
                leadIdToNewStatus.put(newLead.Id, newLead.Status);
            }
        }
    }
    
    // Запускаем единый Queueable только если есть данные для обработки
    if (!leadIdsToProcess.isEmpty() || !changedLeads.isEmpty()) {
        if (!Test.isRunningTest()) {
            // Проверяем лимиты перед запуском Queueable
            if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                UnifiedLeadProcessor processor = new UnifiedLeadProcessor(
                    leadIdsToProcess, 
                    leadIdToNewStatus, 
                    changedLeads,
                    Trigger.isInsert
                );
                System.enqueueJob(processor);
            } else {
                // Если достигнут лимит Queueable, логируем ошибку
                System.debug('Queueable job limit reached. Cannot process lead updates for: ' + leadIdsToProcess);
            }
        } else {
            // В тестовом режиме логируем информацию о том, что Queueable не запускается
            System.debug('Test mode detected. Skipping UnifiedLeadProcessor execution for: ' + leadIdsToProcess);
        }
    }
}