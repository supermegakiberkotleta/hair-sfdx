trigger TwilioCallNumberListTrigger on Twilio_CallNumberList__c (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            TwilioCallNumberListCallout.enqueueCreate(Trigger.new);
        }
        if (Trigger.isUpdate) {
            TwilioCallNumberListCallout.enqueueUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if (Trigger.isDelete) {
            TwilioCallNumberListCallout.enqueueDelete(Trigger.old);
        }
    }
}