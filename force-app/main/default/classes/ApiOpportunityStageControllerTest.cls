@IsTest
private class ApiOpportunityStageControllerTest {

    // ---------- HttpCallout Mocks ----------
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod(), 'Method must be POST');
            System.assert(req.getBody() != null, 'Payload must be sent');

            // Ответ API
            String body =
                '{' +
                '  "transitions": {' +
                '    "0 days": 12,' +
                '    "1-5 days": 3,' +
                '    "6-10 days": 4,' +
                '    "11-15 days": 5,' +
                '    "16-30 days": 6' +
                '  },' +
                '  "returns": {' +
                '    "0 days": 7,' +
                '    "1-5 days": 8,' +
                '    "6-10 days": 9,' +
                '    "11-15 days": 10,' +
                '    "16-30 days": 11' +
                '  }' +
                '}';

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(body);
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('server error');
            return res;
        }
    }

    // ---------- Tests ----------

    @IsTest
    static void testUpdateOpportunityStageReport_success() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        // Запуск обёртки (она дергает future-метод)
        Test.startTest();
        ApiOpportunityStageController.updateOpportunityStageReport('2025-01-01', '2025-01-31', 'boostra');
        Test.stopTest(); // дождаться выполнения @future

        // Проверяем, что вставлены две строки
        List<API_Opportunity_Stage__c> rows = [
            SELECT Column_1__c, Column_2__c, Column_3__c, Column_4__c, Column_5__c, Column_6__c
            FROM API_Opportunity_Stage__c
            ORDER BY Column_1__c
        ];
        System.assertEquals(2, rows.size(), 'Must insert 2 rows');

        API_Opportunity_Stage__c returnsRow;
        API_Opportunity_Stage__c transitionsRow;

        for (API_Opportunity_Stage__c r : rows) {
            if (r.Column_1__c == 'Returns') returnsRow = r;
            if (r.Column_1__c == 'Transitions') transitionsRow = r;
        }

        System.assertNotEquals(null, transitionsRow, 'Transitions row must exist');
        System.assertNotEquals(null, returnsRow, 'Returns row must exist');

        // Transitions значения
        System.assertEquals(12, transitionsRow.Column_2__c);
        System.assertEquals(3,  transitionsRow.Column_3__c);
        System.assertEquals(4,  transitionsRow.Column_4__c);
        System.assertEquals(5,  transitionsRow.Column_5__c);
        System.assertEquals(6,  transitionsRow.Column_6__c);

        // Returns значения
        System.assertEquals(7,  returnsRow.Column_2__c);
        System.assertEquals(8,  returnsRow.Column_3__c);
        System.assertEquals(9,  returnsRow.Column_4__c);
        System.assertEquals(10, returnsRow.Column_5__c);
        System.assertEquals(11, returnsRow.Column_6__c);
    }

    @IsTest
    static void testUpdateOpportunityStageReport_errorResponse() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();
        ApiOpportunityStageController.updateOpportunityStageReport('2025-02-01', '2025-02-28', 'liberty');
        Test.stopTest();

        // При не-200 ничего не вставляется
        Integer countRows = [SELECT COUNT() FROM API_Opportunity_Stage__c];
        System.assertEquals(0, countRows, 'No rows should be inserted on error');
    }
}