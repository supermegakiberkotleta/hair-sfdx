@isTest
private class SendAccountsToQuickBooksBatchTest {

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
        // Создаем Account с нужным RecordTypeId (жестко заданный ID из класса)
        Account a = new Account(Name = 'Test Account', Phone = '1111111', RecordTypeId = '012Kc000000tenBIAQ');
        insert a;

        // Устанавливаем мок
        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        Test.startTest();
        Database.executeBatch(new SendAccountsToQuickBooksBatch(), 1);
        Test.stopTest();

        // Убедимся, что Account остался и обработался
        //System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :a.Id]);
    }
}
