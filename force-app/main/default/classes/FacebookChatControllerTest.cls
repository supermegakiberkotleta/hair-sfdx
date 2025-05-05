@isTest
private class FacebookChatControllerTest {

    @isTest
    static void testGetLeadNameAndPsidWithSupportedObjects() {
        Lead lead = new Lead(LastName='Test Lead', Company='Test Company', Facebook_PSID__c='12345');
        insert lead;

        Test.startTest();
        String name = FacebookChatController.getLeadName ('Lead', lead.Id);
        String psid = FacebookChatController.getRecordPsid('Lead', lead.Id);
        Test.stopTest();

        System.assertEquals('Test Lead', name);
        System.assertEquals('12345', psid);
    }

    @isTest
    static void testUnsupportedObjectThrowsException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            FacebookChatController.getLeadName ('UnsupportedObject', UserInfo.getUserId());
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(true, exceptionThrown, 'AuraHandledException was not thrown for unsupported object');
    }

}
