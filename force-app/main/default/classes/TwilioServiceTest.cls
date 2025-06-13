@IsTest
private class TwilioServiceTest {
    
    // Мок с валидной записью
    private class TwilioMockResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{' +
                '"recordings": [' +
                    '{' +
                        '"media_url": "https://example.com/recording.mp3",' +
                        '"duration": "120.00000",' +
                        '"start_time": "Tue, 11 Jun 2024 12:34:56 +0000"' +
                    '}' +
                ']' +
            '}');
            return res;
        }
    }

    // Мок с пустыми записями
    private class TwilioEmptyResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{ "recordings": [] }');
            return res;
        }
    }

    // Мок с ошибкой 500
    private class TwilioErrorResponse implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    @IsTest
    static void testGetRecordingInfoByConferenceSid_success() {
        Test.setMock(HttpCalloutMock.class, new TwilioMockResponse());

        Test.startTest();
        CallRecordingInfo info = TwilioService.getRecordingInfoByConferenceSid('CF_VALID');
        Test.stopTest();

    
    }

    @IsTest
    static void testGetRecordingInfoByConferenceSid_noRecordings() {
        Test.setMock(HttpCalloutMock.class, new TwilioEmptyResponse());

        Test.startTest();
        CallRecordingInfo info = TwilioService.getRecordingInfoByConferenceSid('CF_EMPTY');
        Test.stopTest();

    }

    @IsTest
    static void testGetRecordingInfoByConferenceSid_errorResponse() {
        Test.setMock(HttpCalloutMock.class, new TwilioErrorResponse());

        Test.startTest();
        CallRecordingInfo info = TwilioService.getRecordingInfoByConferenceSid('CF_ERROR');
        Test.stopTest();

    }
}
