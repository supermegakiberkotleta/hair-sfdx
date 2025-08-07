trigger LeadDeniedStatusTrigger on Lead (before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        // Собираем лиды, которые нужно обработать
        List<Lead> leadsToProcess = new List<Lead>();
        
        for (Lead newLead : Trigger.new) {
            Lead oldLead = Trigger.oldMap.get(newLead.Id);
            
            // Проверяем условия: RecordTypeId и изменение статуса на DENIED
            if (newLead.RecordTypeId == '012Kc000000tenuIAA' && 
                newLead.Status == 'DENIED' && 
                oldLead.Status != 'DENIED') {
                leadsToProcess.add(newLead);
            }
        }
        
        // Если есть лиды для обработки, используем хелпер
        if (!leadsToProcess.isEmpty()) {
            // В before trigger мы можем напрямую изменять поля
            for (Lead lead : leadsToProcess) {
                String newStatus = LeadDeniedStatusHandler.getTargetStatus(lead);
                
                if (String.isNotBlank(newStatus)) {
                    lead.Status = newStatus;
                    System.debug('Lead ' + lead.Id + ' will be updated to status: ' + newStatus);
                }
            }
        }
    }
}