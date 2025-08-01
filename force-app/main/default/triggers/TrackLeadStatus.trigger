trigger TrackLeadStatus on Lead (after insert, after update) {
    Set<Id> leadIdsToProcess = new Set<Id>();
    Map<Id, String> leadIdToNewStatus = new Map<Id, String>();

    if (Trigger.isInsert) {
        // Для новых лидов собираем все ID и статусы
        for (Lead newLead : Trigger.new) {
            if (String.isNotBlank(newLead.Status)) {
                leadIdsToProcess.add(newLead.Id);
                leadIdToNewStatus.put(newLead.Id, newLead.Status);
            }
        }
    }

    if (Trigger.isUpdate) {
        // Для обновлений собираем только те лиды, у которых изменился статус
        for (Lead newLead : Trigger.new) {
            Lead oldLead = Trigger.oldMap.get(newLead.Id);
            if (newLead.Status != oldLead.Status && String.isNotBlank(newLead.Status)) {
                leadIdsToProcess.add(newLead.Id);
                leadIdToNewStatus.put(newLead.Id, newLead.Status);
            }
        }
    }

    // Если есть лиды для обработки, запускаем Queueable
    if (!leadIdsToProcess.isEmpty()) {
        // Проверяем лимиты перед запуском Queueable
        if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
            LeadStatusHistoryQueueable queueable = new LeadStatusHistoryQueueable(
                leadIdsToProcess, 
                leadIdToNewStatus, 
                Trigger.isInsert
            );
            System.enqueueJob(queueable);
        } else {
            // Если достигнут лимит Queueable, логируем ошибку
            System.debug('Queueable job limit reached. Cannot process lead status history for: ' + leadIdsToProcess);
        }
    }
}
