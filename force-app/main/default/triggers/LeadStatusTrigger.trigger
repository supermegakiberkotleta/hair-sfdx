trigger LeadStatusTrigger on Lead (after update) {
    for (Lead newLead : Trigger.new) {
        Lead oldLead = Trigger.oldMap.get(newLead.Id);
        
        if (oldLead.Status != newLead.Status) {
            System.debug('Статус лида изменён: ' + oldLead.Status + ' -> ' + newLead.Status);

            if (newLead.Status == 'Final Denied') {
                LeadStatusHandler.sendRejectionEmail(newLead.Id, newLead.Name, newLead.Status);
                System.debug('Вызывается sendRejectionEmail');
            } else if (newLead.Status == 'Offer sent to broker') {
                LeadStatusHandler.sendOfferEmail(newLead.Id, newLead.Name, newLead.Status);
                System.debug('Вызывается sendOfferEmail');
            }
        }
    }
}