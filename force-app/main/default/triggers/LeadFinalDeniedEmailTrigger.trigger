trigger LeadFinalDeniedEmailTrigger on Lead (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        // Собираем лиды, которые нужно обработать
        List<Lead> leadsToProcess = new List<Lead>();
        
        for (Lead newLead : Trigger.new) {
            Lead oldLead = Trigger.oldMap.get(newLead.Id);
            
            // Проверяем условия:
            // 1. Статус изменился на Final Denied
            // 2. RecordTypeId = 012Kc000000tenuIAA
            // 3. Поле ClosingReasonNew__c не пустое
            if (newLead.Status == 'Final Denied' && 
                oldLead.Status != 'Final Denied' &&
                newLead.RecordTypeId == '012Kc000000tenuIAA' &&
                String.isNotBlank(newLead.ClosingReasonNew__c)) {
                
                leadsToProcess.add(newLead);
                System.debug('Lead ' + newLead.Id + ' meets criteria for denied email notification');
            }
        }
        
        // Если есть лиды для обработки, отправляем email уведомления
        if (!leadsToProcess.isEmpty()) {
            LeadDeniedEmailHandler.processLeadsForEmail(leadsToProcess);
            System.debug('Processing ' + leadsToProcess.size() + ' leads for denied email notifications');
        }
    }
}