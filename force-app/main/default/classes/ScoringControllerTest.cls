@IsTest
private class ScoringControllerTest {

    // Маршрутизирующий мок для нескольких эндпоинтов в одном тесте
    private class RoutingHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type','application/json');

            String endpoint = req.getEndpoint() == null ? '' : req.getEndpoint();

            // Ветка для нужного контроллера (может быть как Named Credential, так и полный URL)
            Boolean isScoringEndpoint = endpoint.contains('scoring-parser');

            if (isScoringEndpoint) {
                System.assertEquals('POST', req.getMethod(), 'Должен выполняться POST-запрос');
                System.assertNotEquals(null, req.getBody(), 'Тело запроса не должно быть пустым');
                System.assert(req.getBody().contains('uuid'), 'Тело должно содержать uuid');

                response.setBody('{"message":"ok"}');
                response.setStatusCode(200);
                return response;
            }

            // Любые прочие вызовы (например, из триггеров/хендлеров) — отвечаем 200, чтобы не валить тест
            response.setBody('{"message":"ok:other-endpoint"}');
            response.setStatusCode(200);
            return response;
        }
    }

    @IsTest
    static void testRunBacklogScoring() {
        // 1) Ставим мок заранее, чтобы покрыть возможные callout'ы при insert
        Test.setMock(HttpCalloutMock.class, new RoutingHttpMock());

        // 2) Готовим данные
        List<Lead> leadsToInsert = new List<Lead>();
        for (Integer index = 0; index < 3; index++) {
            leadsToInsert.add(new Lead(
                LastName = 'TestLead' + index,
                Company = 'TestCompany' + index,
                uuid__c = 'uuid-' + index,
                EIN__c = 'EIN-' + index,
                Loan_Start_Date__c = Date.today().addDays(-index)
            ));
        }
        insert leadsToInsert;

        // 3) Запуск тестируемого метода
        Test.startTest();
        Map<String,Object> result = ScoringController.runBacklogScoring();
        Test.stopTest();

        // 4) Проверки результата
        System.assertNotEquals(null, result, 'Результат не должен быть null');
        System.assert(result.containsKey('statusCode'), 'Результат должен содержать statusCode');
        System.assertEquals(200, (Integer)result.get('statusCode'), 'Код ответа должен быть 200');

        System.assert(result.containsKey('responseBody'), 'Результат должен содержать responseBody');
        String responseBody = (String)result.get('responseBody');
        System.assert(responseBody != null && responseBody.contains('ok'), 'Ответ должен содержать "ok"');

        System.assert(result.containsKey('sentPayload'), 'Результат должен содержать sentPayload');
        Map<String,Object> sentPayload = (Map<String,Object>)result.get('sentPayload');
        System.assert(sentPayload.containsKey('leads'), 'Payload должен содержать ключ leads');

        List<Object> leadsPayload = (List<Object>)sentPayload.get('leads');
        System.assertEquals(3, leadsPayload.size(), 'Количество лидов в payload должно совпадать с созданными данными');
    }
}