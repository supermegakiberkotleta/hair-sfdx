@isTest
private class SendAccountsToQuickBooksBatchTest {

    class SimpleMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"queued"}');
            return res;
        }
    }

    @isTest
    static void testBatchCalloutOnly() {
        // Подготовка тестового аккаунта
        Account acc = new Account(Name = 'Test Account', Phone = '1111111', RecordTypeId = '012Kc000000tenBIAQ');
        insert acc;

        // Установка мок-ответа
        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        // Запуск батча
        Test.startTest();
        Database.executeBatch(new SendAccountsToQuickBooksBatch(), 1);
        Test.stopTest();

        // Проверка, что запись осталась и ошибки не было
        Account result = [SELECT Id, Phone FROM Account WHERE Id = :acc.Id LIMIT 1];
    }
}
