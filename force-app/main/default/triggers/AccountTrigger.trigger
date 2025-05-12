trigger AccountTrigger on Account (before insert, before update) {
    if (Trigger.isBefore) {
        AccountTriggerHandler.handleDeactivation(Trigger.new);
    }
}
