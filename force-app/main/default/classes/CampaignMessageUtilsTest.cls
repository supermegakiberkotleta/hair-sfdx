@isTest
private class CampaignMessageUtilsTest {

    // Успешный мок
    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"ok"}');
            res.setStatusCode(200);
            return res;
        }
    }

    // Мок, который выбрасывает исключение
    class ExceptionThrowingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Mocked exception');
        }
    }

    @isTest static void testGetChatId_AllChannels() {
        Lead testLead = new Lead(
            Facebook_PSID__c = 'fb123',
            Instagram_PSID__c = 'ig456',
            WhatsApp_ID__c = 'wa789',
            Phone = '+1234567890'
        );

    }

    @isTest static void testSendMessageAndSendSalesforceFile_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Boolean messageResult = CampaignMessageUtils.sendMessage('123456', 'Hello!', 'WhatsApp');
        Boolean fileResult = CampaignMessageUtils.sendSalesforceFile('123456', '068XXX000000AAA', 'WhatsApp');

    }

    @isTest static void testSendMessage_Exception() {
        Test.setMock(HttpCalloutMock.class, new ExceptionThrowingMock());

        Boolean result = CampaignMessageUtils.sendMessage('123456', 'Test', 'Facebook');
    }

    @isTest static void testSendSalesforceFile_Exception() {
        Test.setMock(HttpCalloutMock.class, new ExceptionThrowingMock());

        Boolean result = CampaignMessageUtils.sendSalesforceFile('123456', '068XXX000000BBB', 'Instagram');
    }
}
