trigger AccountTrigger on Account (before insert, before update, after insert) {
    if (Trigger.isBefore) {
        AccountTriggerHandler.handleDeactivation(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        AccountTriggerHandler.handleAccountSync(Trigger.new);
    }
}