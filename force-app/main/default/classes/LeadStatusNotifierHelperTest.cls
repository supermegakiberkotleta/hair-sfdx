@isTest
private class LeadStatusNotifierHelperTest {

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
    static void testSendHttpPost_Success() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Lead testLead = [SELECT Id, Name FROM Lead LIMIT 1];
        LeadStatusNotifierHelper.sendHttpPost(
            'https://example.com/api/test',
            testLead.Id,
            testLead.Name,
            'New'
        );

        Test.stopTest();
    }

    // Внутренний мок должен быть внутри тестового класса
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "success"}');
            return res;
        }
    }
}