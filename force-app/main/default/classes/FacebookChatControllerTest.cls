@isTest
private class FacebookChatControllerTest {

    @isTest
    static void testGetLeadNameAndPsid() {
        Lead l = new Lead(LastName = 'FB Lead', Company = 'FB Co', Facebook_PSID__c = 'fb_lead_123');
        insert l;

        Test.startTest();
        String name = FacebookChatController.getLeadName('Lead', l.Id);
        String psid = FacebookChatController.getRecordPsid('Lead', l.Id);
        Test.stopTest();

        System.assertEquals('FB Lead', name);
        System.assertEquals('fb_lead_123', psid);
    }

    @isTest
    static void testGetContactNameAndPsid() {
        Contact c = new Contact(LastName = 'FB Contact', Facebook_PSID__c = 'fb_contact_123');
        insert c;

        Test.startTest();
        String name = FacebookChatController.getLeadName('Contact', c.Id);
        String psid = FacebookChatController.getRecordPsid('Contact', c.Id);
        Test.stopTest();

        System.assertEquals('FB Contact', name);
        System.assertEquals('fb_contact_123', psid);
    }

    @isTest
    static void testGetAccountNameAndPsid() {
        Account a = new Account(Name = 'FB Account', Facebook_PSID__c = 'fb_account_123');
        insert a;

        Test.startTest();
        String name = FacebookChatController.getLeadName('Account', a.Id);
        String psid = FacebookChatController.getRecordPsid('Account', a.Id);
        Test.stopTest();

        System.assertEquals('FB Account', name);
        System.assertEquals('fb_account_123', psid);
    }

    @isTest
    static void testGetOpportunityNameAndPsid() {
        Opportunity o = new Opportunity(Name = 'FB Opp', StageName = 'Qualification', CloseDate = Date.today(), Facebook_PSID__c = 'fb_opp_123');
        insert o;

        Test.startTest();
        String name = FacebookChatController.getLeadName('Opportunity', o.Id);
        String psid = FacebookChatController.getRecordPsid('Opportunity', o.Id);
        Test.stopTest();

        System.assertEquals('FB Opp', name);
        System.assertEquals('fb_opp_123', psid);
    }

    @isTest
    static void testUnsupportedObjectName() {
        Test.startTest();
        try {
            FacebookChatController.getLeadName('CustomObject__c', Id.valueOf('001000000000001AAA'));
            System.assert(false);
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Unsupported object'));
        }

        try {
            FacebookChatController.getRecordPsid('CustomObject__c', Id.valueOf('001000000000001AAA'));
            System.assert(false);
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Unsupported object'));
        }
        Test.stopTest();
    }
}
