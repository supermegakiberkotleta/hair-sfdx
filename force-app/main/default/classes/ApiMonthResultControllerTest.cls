@IsTest
private class ApiMonthResultControllerTest {

    // Мок успешного ответа: корень — таблица (List<List<Object>>)
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            // [["Jan 2025","10","20"],["Feb 2025","30","40"]]
            List<Object> row1 = new List<Object>{'Jan 2025','10','20'};
            List<Object> row2 = new List<Object>{'Feb 2025','30','40'};
            List<Object> table = new List<Object>{row1, row2};

            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setBody(JSON.serialize(table));
            response.setHeader('Content-Type','application/json');
            return response;
        }
    }

    // Мок ошибки API: ничего не удаляется и не вставляется
    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest request) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(500);
            response.setBody('{"error":"server"}');
            response.setHeader('Content-Type','application/json');
            return response;
        }
    }

    @IsTest
    static void testSuccess_InsertsAndMaps() {
        // Добавим старые записи — должны удалиться при успешном ответе
        insert new API_Month_Result__c(Column_1__c='old1');
        insert new API_Month_Result__c(Column_1__c='old2');

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        ApiMonthResultController.updateMonthResultReport('2025-01-01','2025-01-31','boostra');
        Test.stopTest();

        // Старые удалены, вставлены 2 новые
        List<API_Month_Result__c> created = [
            SELECT Column_1__c, Column_2__c, Column_3__c
            FROM API_Month_Result__c
            ORDER BY CreatedDate ASC
        ];
        System.assertEquals(2, created.size(), 'Должно быть 2 новые записи');

        // Первая строка
        System.assertEquals('Jan 2025', created[0].Column_1__c);
        System.assertEquals('10', created[0].Column_2__c);
        System.assertEquals('20', created[0].Column_3__c);

        // Вторая строка
        System.assertEquals('Feb 2025', created[1].Column_1__c);
        System.assertEquals('30', created[1].Column_2__c);
        System.assertEquals('40', created[1].Column_3__c);
    }

    @IsTest
    static void testErrorStatus_NoChanges() {
        // Если API вернул не 200, метод делает return и НЕ трогает базу
        insert new API_Month_Result__c(Column_1__c='keep_me');

        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();
        ApiMonthResultController.updateMonthResultReport('2025-02-01','2025-02-28','boostra');
        Test.stopTest();

        Integer count = [SELECT COUNT() FROM API_Month_Result__c];
        System.assertEquals(1, count, 'При ошибке API записи не должны меняться');
    }
}