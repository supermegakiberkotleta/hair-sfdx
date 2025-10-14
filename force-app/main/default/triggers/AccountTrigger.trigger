trigger AccountTrigger on Account (before insert, before update, after insert, after update, before delete) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        AccountTriggerHandler.handleDeactivation(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        AccountTriggerHandler.handleMarketingReportInsert(Trigger.new);
        AccountTriggerHandler.handleAccountSync(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.handleMarketingReportUpdate(Trigger.new, Trigger.old);
    }
    
    if (Trigger.isBefore && Trigger.isDelete) {
        AccountTriggerHandler.handleMarketingReportDelete(Trigger.old);
    }
}