trigger AutodialCampaignManagerTrigger on Autodial_CampaignManager__c (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AutodialCampaignManagerCallout.enqueueCreate(Trigger.new);
        }
        if (Trigger.isUpdate) {
            AutodialCampaignManagerCallout.enqueueUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if (Trigger.isDelete) {
            AutodialCampaignManagerCallout.enqueueDelete(Trigger.old);
        }
    }
}