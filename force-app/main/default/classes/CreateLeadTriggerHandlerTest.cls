@isTest
private class CreateLeadTriggerHandlerTest {
    @isTest
    static void testSendLeadDataToExternalService() {
        Lead lead = new Lead(Name__c='Test Lead');
        List<Lead> leads = new List<Lead>();

        leads.add(lead);

        String payload = JSON.serialize(leads);

        Test.startTest();
        CreateLeadTriggerHandler.sendLeadDataToExternalService(payload);
        Test.stopTest();
    }
}