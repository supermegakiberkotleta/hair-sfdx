@isTest
private class WhatsappChatControllerTest {

    @isTest
    static void testGetLeadNameAndPsidWithSupportedObjects() {
        Lead lead = new Lead(LastName='Test WhatsApp Lead', Company='Test Company', Whatsapp_ID__c='wa-12345');
        insert lead;

        Test.startTest();
        String name = WhatsappChatController.getLeadName ('Lead', lead.Id);
        String psid = WhatsappChatController.getRecordPsid('Lead', lead.Id);
        Test.stopTest();

        System.assertEquals('Test WhatsApp Lead', name);
        System.assertEquals('wa-12345', psid);
    }

    @isTest
    static void testUnsupportedObjectThrowsException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            WhatsappChatController.getLeadName ('UnsupportedObject', UserInfo.getUserId());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'AuraHandledException was not thrown for unsupported object');
    }
}
