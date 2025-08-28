@IsTest
private class SendOpportunityUpdateJobTest {

    // Статическое поле ДОЛЖНО быть во внешнем классе
    private static HttpRequest capturedRequest;

    /** Мок, возвращающий успешный ответ и сохраняющий запрос */
    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // сохраняем запрос во внешнее статическое поле
            SendOpportunityUpdateJobTest.capturedRequest = req;

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"ok":true}');
            return res;
        }
    }

    /** Мок, выбрасывающий исключение для проверки ветки catch */
    private class ExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated failure');
        }
    }

    @IsTest
    static void testSuccessCalloutAndPayload() {
        String oppId = '006XXXXXXXXXXXXAAA';
        String leadId = '00QXXXXXXXXXXXXAAA';
        String reportLink = 'https://example.com/report.pdf';

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Id jobId = System.enqueueJob(new SendOpportunityUpdateJob(oppId, leadId, reportLink));
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Ожидается Id очереди');
        System.assertNotEquals(null, capturedRequest, 'Запрос должен быть перехвачен мок-классом');

        System.assertEquals('https://lenderpro.itprofit.net/api/v1/opportunity-update',
                            capturedRequest.getEndpoint(), 'Неверный endpoint');
        System.assertEquals('POST', capturedRequest.getMethod(), 'Метод должен быть POST');
        System.assertEquals('application/json', capturedRequest.getHeader('Content-Type'),
                            'Content-Type должен быть application/json');

        Map<String, Object> got = (Map<String, Object>) JSON.deserializeUntyped(capturedRequest.getBody());
        System.assertEquals(oppId, (String) got.get('opportunityId'));
        System.assertEquals(leadId, (String) got.get('leadId'));
        System.assertEquals(reportLink, (String) got.get('reportFileLink'));
    }

    @IsTest
    static void testCalloutExceptionHandled() {
        String oppId = '006AAA';
        String leadId = '00QBBB';
        String reportLink = 'https://example.com/x.pdf';

        Test.setMock(HttpCalloutMock.class, new ExceptionMock());

        Test.startTest();
        Id jobId = System.enqueueJob(new SendOpportunityUpdateJob(oppId, leadId, reportLink));
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Джоба не должна падать при исключении callout');
    }
}