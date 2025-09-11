trigger AutodialCampaignMembersTrigger on Autodial_CampaignMembers__c (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AutodialCampaignMembersCallout.enqueueCreate(Trigger.new);
        }
        if (Trigger.isUpdate) {
            AutodialCampaignMembersCallout.enqueueUpdate(Trigger.oldMap, Trigger.newMap);
        }
        if (Trigger.isDelete) {
            AutodialCampaignMembersCallout.enqueueDelete(Trigger.old);
        }
    }
}