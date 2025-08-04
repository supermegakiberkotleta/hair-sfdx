trigger CampaignTrigger on Campaign (after update) {
    for (Campaign c : Trigger.new) {
        Campaign oldC = Trigger.oldMap.get(c.Id);
        if (c.Status == 'In Progress' && oldC.Status != 'In Progress') {
            Database.executeBatch(new CampaignMessageBatch(c.Id), 50);
        }
    }
}