@isTest
private class CampaignMessageSchedulerTest {

    @isTest
    static void testSchedulerExecution() {
        Campaign camp = new Campaign(
            Name = 'Scheduled Campaign',
            Type = 'Facebook',
            Status = 'Scheduled',
            Message__c = 'Scheduled message',
            Scheduled_Date__c = System.now()
        );
        insert camp;

        Test.startTest();
        CampaignMessageScheduler.execute(null);
        Test.stopTest();
    }

    @isTest
    static void testSchedulerNoCampaigns() {
        Test.startTest();
        CampaignMessageScheduler.execute(null);
        Test.stopTest();
    }
}
