trigger LeadTrigger on Lead (before insert, before update) {
    if (Trigger.isBefore) {
        LeadTriggerHandler.handleDeactivation(Trigger.new);
    }
}
