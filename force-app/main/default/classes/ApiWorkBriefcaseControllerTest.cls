@IsTest
private class ApiWorkBriefcaseControllerTest {

    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // эмулируем JSON-таблицу [["A","B","C"],["D","E","F"]]
            List<Object> row1 = new List<Object>{'A','B','C'};
            List<Object> row2 = new List<Object>{'D','E','F'};
            List<Object> table = new List<Object>{row1,row2};
            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(table));
            res.setHeader('Content-Type','application/json');
            return res;
        }
    }

    @IsTest
    static void testUpdateWorkBriefcaseReport() {
        // подставляем мок
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        ApiWorkBriefcaseController.updateWorkBriefcaseReport('2025-01-01','2025-01-31','boostra');
        Test.stopTest(); // ждём выполнения future

        // проверим, что записи вставились
        List<API_Work_Briefcase__c> records = [
            SELECT Column_1__c, Column_2__c, Column_3__c 
            FROM API_Work_Briefcase__c
        ];

        System.assertEquals(2, records.size(), 'Должно быть 2 записи');
        System.assertEquals('A', records[0].Column_1__c);
        System.assertEquals('B', records[0].Column_2__c);
        System.assertEquals('C', records[0].Column_3__c);
    }
}