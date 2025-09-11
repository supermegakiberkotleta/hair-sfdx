trigger AutodialCampaignTrigger on Autodial_Campaign__c (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AutodialCampaignCallout.enqueueCreate(Trigger.new);
        }
        if (Trigger.isUpdate) {
            AutodialCampaignCallout.enqueueUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if (Trigger.isDelete) {
            AutodialCampaignCallout.enqueueDelete(Trigger.old);
        }
    }
}