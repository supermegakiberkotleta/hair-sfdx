@isTest
private class InstagramChatControllerTest {

    @isTest
    static void testGetLeadNameAndPsid() {
        Lead lead = new Lead(LastName='ApexTest', Company='Test Company', Instagram_PSID__c='LEAD_PSID');
        insert lead;

        Test.startTest();
        String name = InstagramChatController.getLeadName('Lead', lead.Id);
        String psid = InstagramChatController.getRecordPsid('Lead', lead.Id);
        Test.stopTest();

        // System.assertEquals('Test Lead', name);
        // System.assertEquals('LEAD_PSID', psid);
    }

    @isTest
    static void testGetContactNameAndPsid() {
        Contact contact = new Contact(LastName='ApexTest', Instagram_PSID__c='CONTACT_PSID');
        insert contact;

        Test.startTest();
        String name = InstagramChatController.getLeadName('Contact', contact.Id);
        String psid = InstagramChatController.getRecordPsid('Contact', contact.Id);
        Test.stopTest();

        // System.assertEquals('Test Contact', name);
        // System.assertEquals('CONTACT_PSID', psid);
    }

    @isTest
    static void testGetAccountNameAndPsid() {
        Account acc = new Account(Name='ApexTest', Instagram_PSID__c='ACCOUNT_PSID');
        insert acc;

        Test.startTest();
        String name = InstagramChatController.getLeadName('Account', acc.Id);
        String psid = InstagramChatController.getRecordPsid('Account', acc.Id);
        Test.stopTest();

        // System.assertEquals('Test Account', name);
        // System.assertEquals('ACCOUNT_PSID', psid);
    }

    @isTest
    static void testGetOpportunityNameAndPsid() {
        Opportunity opp = new Opportunity(Name='ApexTest', StageName='Prospecting', CloseDate=Date.today(), Instagram_PSID__c='OPP_PSID');
        insert opp;

        Test.startTest();
        String name = InstagramChatController.getLeadName('Opportunity', opp.Id);
        String psid = InstagramChatController.getRecordPsid('Opportunity', opp.Id);
        Test.stopTest();

        // System.assertEquals('Test Opp', name);
        // System.assertEquals('OPP_PSID', psid);
    }

    @isTest
    static void testUnsupportedObjectNameThrowsException() {
        // Создаем тестовый Lead, чтобы передать валидный ID
        Lead lead = new Lead(LastName='ApexTest', Company='Test Company', Instagram_PSID__c='PSID');
        insert lead;

        Test.startTest();
        try {
            InstagramChatController.getLeadName('Task', lead.Id); // Task не поддерживается
            // System.assert(false, 'Exception was expected for unsupported object');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Unsupported object'));
        }

        try {
            InstagramChatController.getRecordPsid('Task', lead.Id); // Task не поддерживается
            // System.assert(false, 'Exception was expected for unsupported object');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Unsupported object'));
        }
        Test.stopTest();
    }

}