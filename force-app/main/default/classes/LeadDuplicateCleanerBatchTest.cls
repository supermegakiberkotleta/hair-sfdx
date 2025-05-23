@isTest
private class LeadDuplicateCleanerBatchTest {
    @isTest
    static void testLeadDuplicateCleaner() {
        List<Lead> leads = new List<Lead>();

        leads.add(new Lead(LastName = 'Lead A', RecordTypeId = '012Kc000000ten6IAA', Company = 'Test', Status = 'New', WhatsApp_ID__c = '123'));
        leads.add(new Lead(LastName = 'Lead B', RecordTypeId = '012Kc000000ten6IAA', Company = 'Test', Status = 'Closed Lost', Reason_for_closure__c = 'Undefined reason', WhatsApp_ID__c = '123'));
        leads.add(new Lead(LastName = 'Lead C', RecordTypeId = '012Kc000000ten6IAA', Company = 'Test', Status = 'New', WhatsApp_ID__c = '123'));

        leads.add(new Lead(LastName = 'Lead D', RecordTypeId = '012Kc000000ten6IAA', Company = 'Test', Status = 'New', Instagram_PSID__c= 'fb_001'));
        leads.add(new Lead(LastName = 'Lead E', RecordTypeId = '012Kc000000ten6IAA', Company = 'Test', Status = 'New', Instagram_PSID__c= 'fb_001'));

        insert leads;

        Test.startTest();
        Database.executeBatch(new LeadDuplicateCleanerBatch(), 50);
        Test.stopTest();

        List<Lead> remaining = [SELECT Id, WhatsApp_ID__c, Facebook_PSID__c, Status FROM Lead WHERE WhatsApp_ID__c = '123' OR Instagram_PSID__c= 'fb_001'];
        //System.assertEquals(2, remaining.size(), 'Должно остаться по одному лиду из каждой группы');
        for (Lead l : remaining) {
            //System.assertNotEquals('Closed Lost', l.Status, 'Closed Lost лид должен быть удалён');
        }
    }
}
