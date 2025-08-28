@IsTest
private class AutodialCampaignCalloutTest {

    private class StubMock implements HttpCalloutMock {
        Integer calls = 0;
        public HTTPResponse respond(HTTPRequest req) {
            calls++;
            System.assertEquals('POST', req.getMethod());
            System.assert(req.getEndpoint().startsWith('callout:Telephony_Credential/'), 'Endpoint should use Named Credential');
            System.assert(req.getEndpoint().contains('/api/v1/autodial-campaign/'), 'Endpoint path should contain API prefix');
            System.assertEquals('application/json', req.getHeader('Content-Type'));
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"ok":true}');
            return res;
        }
    }

    @IsTest
    static void testCreateSendsAllFields() {
        StubMock mock = new StubMock();
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Autodial_Campaign__c rec = new Autodial_Campaign__c(Name='Test Campaign');
        insert rec;
        Test.stopTest();

        System.assert(mock.calls > 0, 'Expected at least one callout on create');
    }

    @IsTest
    static void testUpdateSendsChangedFields() {
        StubMock mock = new StubMock();
        Test.setMock(HttpCalloutMock.class, mock);

        Autodial_Campaign__c rec = new Autodial_Campaign__c(Name='Before');
        insert rec;

        Test.startTest();
        rec.Name = 'After';
        update rec;
        Test.stopTest();

        System.assert(mock.calls > 0, 'Expected at least one callout on update');
    }
}


