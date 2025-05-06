@isTest
private class CampaignMessageBatchTest {

    private static Campaign createTestCampaign(String type) {
        Campaign camp = new Campaign(Name = 'Test Campaign', Type = type, Status = 'Planned');
        camp.Message__c = 'Test Message';
        insert camp;
        return camp;
    }

    private static Lead createLead(String psid, String email) {
        Lead l = new Lead(
            LastName = 'Test',
            Company = 'Test Co',
            Facebook_PSID__c = psid,
            Instagram_PSID__c = psid,
            WhatsApp_ID__c = psid,
            Phone = '1234567890',
            Email = email
        );
        return l;
    }

    @isTest
    static void testBatchExecution_AllSuccess() {
        Campaign camp = createTestCampaign('Facebook');
        Lead l = createLead('psid123', 'l1@test.com');
        insert l;
        insert new CampaignMember(CampaignId = camp.Id, LeadId = l.Id);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());
        Database.executeBatch(new CampaignMessageBatch(camp.Id), 200);
        Test.stopTest();

        Campaign updated = [SELECT Success_Count__c FROM Campaign WHERE Id = :camp.Id];
        System.assertEquals(1, updated.Success_Count__c);
    }

    @isTest
    static void testBatchExecution_CampaignMemberWithoutLinks() {
        Campaign camp = createTestCampaign('Instagram');
        Lead dummy = createLead('psidX', 'dummy@test.com');
        insert dummy;

        insert new CampaignMember(CampaignId = camp.Id, LeadId = dummy.Id);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());
        Database.executeBatch(new CampaignMessageBatch(camp.Id), 200);
        Test.stopTest();

        Campaign updated = [SELECT Success_Count__c FROM Campaign WHERE Id = :camp.Id];
        System.assertEquals(1, updated.Success_Count__c);
    }

    @isTest
    static void testBatchExecution_DuplicateLeads() {
        Campaign camp = createTestCampaign('WhatsApp');
        Lead l1 = createLead('same-psid', 'dup1@test.com');
        Lead l2 = createLead('same-psid', 'dup2@test.com'); // уникальный email

        insert new List<Lead>{ l1, l2 };

        insert new List<CampaignMember>{
            new CampaignMember(CampaignId = camp.Id, LeadId = l1.Id),
            new CampaignMember(CampaignId = camp.Id, LeadId = l2.Id)
        };

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockSuccessResponse());
        Database.executeBatch(new CampaignMessageBatch(camp.Id), 200);
        Test.stopTest();

        Campaign updated = [SELECT Success_Count__c FROM Campaign WHERE Id = :camp.Id];
        System.assertEquals(2, updated.Success_Count__c);
    }
}
