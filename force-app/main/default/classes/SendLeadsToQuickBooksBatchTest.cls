@isTest
private class SendLeadsToQuickBooksBatchTest {

    class SimpleMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Last_Sale_Date":"2024-01-01","Outstanding_Balance":100.0,"Customer_Category":"Test","Sales_2024":200}');
            return res;
        }
    }

    @isTest
    static void testBatchMinimal() {
        // Создаем лида с нужным RecordTypeId (жестко заданный ID из класса)
        Lead l = new Lead(LastName = 'Test', Company = 'TestCo', Phone = '1111111', RecordTypeId = '012Kc000000ten6IAA');
        insert l;

        // Устанавливаем мок
        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        Test.startTest();
        Database.executeBatch(new SendLeadsToQuickBooksBatch(), 1);
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE Id = :l.Id]);
    }
}