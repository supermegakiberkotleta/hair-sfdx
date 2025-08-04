@isTest
private class LeadStatusHandlerTest {

    @testSetup
    static void setupTestData() {
        Lead testLead = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Company = 'Test Company',
            Status = 'New'
        );
        insert testLead;
    }

    @isTest
    static void testSendRejectionEmail() {
        Test.startTest();
        Lead testLead = [SELECT Id, Name, Status FROM Lead LIMIT 1];
        LeadStatusHandler.sendRejectionEmail(testLead.Id, testLead.Name, 'Rejected');
        Test.stopTest();
    }

    @isTest
    static void testSendOfferEmail() {
        Test.startTest();
        Lead testLead = [SELECT Id, Name, Status FROM Lead LIMIT 1];
        LeadStatusHandler.sendOfferEmail(testLead.Id, testLead.Name, 'Qualified');
        Test.stopTest();
    }
}