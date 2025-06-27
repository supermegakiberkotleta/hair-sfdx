@isTest
private class CampaignMessageBatchDebugTest {

    @isTest
    static void testBatchExecution() {
        // 1. Setup Campaign
        Campaign camp = new Campaign(
            Name = 'Test Campaign',
            Type = 'Facebook',
            Status = 'Planned',
            Message__c = 'Test message'
        );
        insert camp;

        // 2. Setup Lead
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Co',
            Facebook_PSID__c = 'fb_test_id'
        );
        insert lead;

        // 3. Create CampaignMember
        CampaignMember cm = new CampaignMember(
            CampaignId = camp.Id,
            LeadId = lead.Id,
            Status = 'Planned'
        );
        insert cm;

        // 4. Execute batch
        Test.startTest();
        Database.executeBatch(new CampaignMessageBatchDebug(camp.Id), 1);
        Test.stopTest();

        // 5. Validate result
        Campaign updatedCamp = [SELECT Status, Success_Count__c FROM Campaign WHERE Id = :camp.Id];
        System.assertEquals('Completed', updatedCamp.Status);
        //System.assertEquals(1, updatedCamp.Success_Count__c);
    }
}