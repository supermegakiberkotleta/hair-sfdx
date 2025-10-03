@isTest
private class ApiBrokersCommissionsControllerTest {

    // Мок для имитации ответа внешнего API
    private class BrokersCommissionsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals(
                'https://lenderpro.itprofit.net/api/v1/report/brokers-commissions',
                req.getEndpoint(),
                'Должен вызываться правильный endpoint'
            );
            System.assertEquals('POST', req.getMethod(), 'Метод должен быть POST');

            // Пример "таблицы": заголовок + 2 строки
            String mockBody = JSON.serialize(new List<List<Object>>{
                new List<Object>{'Broker','Month','Amount'},
                new List<Object>{'John Doe','2025-08','1000'},
                new List<Object>{'Jane Smith','2025-08','2000'}
            });

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(mockBody);
            return res;
        }
    }

    @isTest
    static void testUpdateBrokersCommissionsReport() {
        // Регистрируем мок
        Test.setMock(HttpCalloutMock.class, new BrokersCommissionsMock());

        Test.startTest();
        // Вызов основного метода (он дергает future-метод)
        ApiBrokersCommissionsController.updateBrokersCommissionsReport('Boostra Florida Corp');
        Test.stopTest(); // дождаться выполнения @future
       
        // Проверяем, что записи сохранились
        List<API_Brokers_Commissions__c> records = [
            SELECT Column_1__c, Column_2__c, Column_3__c
            FROM API_Brokers_Commissions__c
        ];

        System.assertEquals(3, records.size(), 'Должно быть 3 строки (заголовок + 2 строки данных)');
        System.assertEquals('Broker', records[0].Column_1__c);
        System.assertEquals('John Doe', records[1].Column_1__c);
        System.assertEquals('Jane Smith', records[2].Column_1__c);
    }
}