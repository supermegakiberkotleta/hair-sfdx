@isTest
private class InstagramChatControllerTest {

    @isTest
    static void testGetLeadNameAndPsidWithSupportedObjects() {
        Lead lead = new Lead(LastName='Test IG Lead', Company='Test IG Company', Instagram_PSID__c='ig-psid-001');
        insert lead;

        Test.startTest();
        String name = InstagramChatController.getLeadName ('Lead', lead.Id);
        String psid = InstagramChatController.getRecordPsid('Lead', lead.Id);
        Test.stopTest();

        System.assertEquals('Test IG Lead', name);
        System.assertEquals('ig-psid-001', psid);
    }

    @isTest
    static void testUnsupportedObjectThrowsException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            InstagramChatController.getLeadName ('UnsupportedObject', UserInfo.getUserId());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'AuraHandledException was not thrown for unsupported object');
    }
}
