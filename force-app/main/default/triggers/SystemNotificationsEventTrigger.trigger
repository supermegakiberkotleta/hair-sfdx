trigger SystemNotificationsEventTrigger on System_Notifications__e (after insert) {
    SystemNotificationsEventHandler.handleAfterInsert(Trigger.new);
}