global class CampaignMessageScheduler implements Schedulable {
    global void execute(SchedulableContext SC) {
        List<Campaign> scheduled = [SELECT Id FROM Campaign WHERE Status = 'Planned' AND Scheduled_Date__c <= :System.now()];
        for (Campaign c : scheduled) {
            c.Status = 'In Progress';
            update c;
            Database.executeBatch(new CampaignMessageBatch(c.Id), 50);
        }
    }
}