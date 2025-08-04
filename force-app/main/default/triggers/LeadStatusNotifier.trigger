trigger LeadStatusNotifier on Lead (after update) {
   
 
        for (Lead newLead : Trigger.new) {
            Lead oldLead = Trigger.oldMap.get(newLead.Id);

            if (oldLead.Status != newLead.Status) {
                if (newLead.Status == 'Final Denied') {
                    LeadEmailSender.sendRejectionEmail(newLead.Id, newLead.Name, newLead.Status);
                } else if (newLead.Status == 'Offer sent to broker') {
                    LeadEmailSender.sendOfferEmail(newLead.Id, newLead.Name, newLead.Status);
                }
            }
        }
   
}