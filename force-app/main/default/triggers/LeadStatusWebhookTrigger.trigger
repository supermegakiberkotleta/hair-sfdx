trigger LeadStatusWebhookTrigger on Lead (after update) {
    for (Lead newLead : Trigger.new) {
        Lead oldLead = Trigger.oldMap.get(newLead.Id);
        if (newLead.Status == 'Call after' && oldLead.Status != 'Call after') {
            LeadStatusWebhookSender.sendLeadStatusWebhook(
                newLead.Id,
                newLead.Name
            );
        }
    }
}