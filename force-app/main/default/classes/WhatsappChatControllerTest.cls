@isTest
private class WhatsappChatControllerTest {

    @isTest
    static void testGetLeadNameAndPsid() {
        // Lead
        Lead l = new Lead(LastName = 'Test Lead', Company = 'Test Co', Whatsapp_ID__c = 'wa_lead_123');
        insert l;

        Test.startTest();
        String name = WhatsappChatController.getLeadName('Lead', l.Id);
        String psid = WhatsappChatController.getRecordPsid('Lead', l.Id);
        Test.stopTest();

        System.assertEquals('Test Lead', name);
        System.assertEquals('wa_lead_123', psid);
    }

    @isTest
    static void testGetContactNameAndPsid() {
        Contact c = new Contact(LastName = 'Test Contact', Whatsapp_ID__c = 'wa_contact_123');
        insert c;

        Test.startTest();
        String name = WhatsappChatController.getLeadName('Contact', c.Id);
        String psid = WhatsappChatController.getRecordPsid('Contact', c.Id);
        Test.stopTest();

        System.assertEquals('Test Contact', name);
        System.assertEquals('wa_contact_123', psid);
    }

    @isTest
    static void testGetAccountNameAndPsid() {
        Account a = new Account(Name = 'Test Account', Whatsapp_ID__c = 'wa_account_123');
        insert a;

        Test.startTest();
        String name = WhatsappChatController.getLeadName('Account', a.Id);
        String psid = WhatsappChatController.getRecordPsid('Account', a.Id);
        Test.stopTest();

        System.assertEquals('Test Account', name);
        System.assertEquals('wa_account_123', psid);
    }

    @isTest
    static void testGetOpportunityNameAndPsid() {
        Opportunity o = new Opportunity(Name = 'Test Opp', StageName = 'Prospecting', CloseDate = Date.today(), Whatsapp_ID__c = 'wa_opp_123');
        insert o;

        Test.startTest();
        String name = WhatsappChatController.getLeadName('Opportunity', o.Id);
        String psid = WhatsappChatController.getRecordPsid('Opportunity', o.Id);
        Test.stopTest();

        System.assertEquals('Test Opp', name);
        System.assertEquals('wa_opp_123', psid);
    }

    @isTest
    static void testUnsupportedObjectName() {
        Test.startTest();
        try {
            WhatsappChatController.getLeadName('CustomObject__c', Id.valueOf('001000000000001AAA'));
            System.assert(false); // Не должно доходить сюда
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Unsupported object'));
        }
        try {
            WhatsappChatController.getRecordPsid('CustomObject__c', Id.valueOf('001000000000001AAA'));
            System.assert(false);
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Unsupported object'));
        }
        Test.stopTest();
    }
}
