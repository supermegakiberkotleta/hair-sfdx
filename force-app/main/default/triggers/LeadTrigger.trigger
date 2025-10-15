trigger LeadTrigger on Lead (before insert, before update, after update) {
    if (Trigger.isBefore) {
        LeadTriggerHandler.handleDeactivation(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        List<Lead> converted = new List<Lead>();
        for (Lead l : Trigger.new) {
            Lead oldL = Trigger.oldMap.get(l.Id);
            if (l.IsConverted && !oldL.IsConverted && l.ConvertedAccountId != null) {
                converted.add(l);
            }
        }
        if (!converted.isEmpty()) {
            AccountTriggerHandler.handleMarketingReportInsert(converted);
        }
    }
}