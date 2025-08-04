trigger LeadWebhookUpdate on Lead (after update) {
    List<Map<String, Object>> changedLeads = new List<Map<String, Object>>();
    for (Integer i = 0; i < Trigger.new.size(); i++) {
        Lead oldLead = Trigger.old[i];
        Lead newLead = Trigger.new[i];
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
    if (!changedLeads.isEmpty()) {
        System.enqueueJob(new LeadUpdateWebhookSender(changedLeads));
    }
}