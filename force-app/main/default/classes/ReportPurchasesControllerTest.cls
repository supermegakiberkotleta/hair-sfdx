@isTest
private class ReportPurchasesControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестового клиента
        Marketing_Report_Customer__c customer = new Marketing_Report_Customer__c();
        customer.Budget__c = 1000.00;
        customer.Active__c = true;
        insert customer;
        
        // Создаем тестовую покупку для обновления
        Marketing_Report_Purchase__c existingPurchase = new Marketing_Report_Purchase__c();
        existingPurchase.Marketing_Report_Customer__c = customer.Id;
        existingPurchase.Purchase_Amount__c = 500.00;
        existingPurchase.Date_Buy__c = Date.today();
        existingPurchase.Month_Buy__c = 1;
        existingPurchase.Week_Buy__c = 1;
        insert existingPurchase;
    }
    
    @isTest
    static void testProcessPurchasesWithNewRecords() {
        // Получаем созданного клиента
        Marketing_Report_Customer__c customer = [SELECT Id FROM Marketing_Report_Customer__c LIMIT 1];
        
        // Подготавливаем тестовый запрос с новыми покупками
        Map<String, Object> requestData = new Map<String, Object>{
            'customerId' => customer.Id,
            'budget' => 129.45,
            'active' => true,
            'page' => 1,
            'totalPages' => 2,
            'purchases' => new List<Object>{
                new Map<String, Object>{
                    'Purchase_Amount__c' => 457.32,
                    'Date_Buy__c' => '2025-07-09',
                    'Month_Buy__c' => 7,
                    'Week_Buy__c' => 28
                },
                new Map<String, Object>{
                    'Purchase_Amount__c' => 123.45,
                    'Date_Buy__c' => '2025-07-10',
                    'Month_Buy__c' => 7,
                    'Week_Buy__c' => 28
                }
            }
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/report-purchases/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(requestData));
        req.addHeader('Content-Type', 'application/json');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        ReportPurchasesController.processPurchases();
        
        Test.stopTest();
        
        // Проверяем ответ
        System.assertEquals(200, res.statusCode, 'Expected status code 200');
        
        String responseString = res.responseBody.toString();
        System.assert(responseString.contains('success'), 'Response should contain success');
        
        // Проверяем что записи созданы
        List<Marketing_Report_Purchase__c> createdPurchases = [
            SELECT Id, Purchase_Amount__c, Date_Buy__c, Month_Buy__c, Week_Buy__c
            FROM Marketing_Report_Purchase__c
            WHERE Marketing_Report_Customer__c = :customer.Id
        ];
        
        System.assertEquals(3, createdPurchases.size(), 'Should have 3 purchases (1 existing + 2 new)');
    }
    
    @isTest
    static void testProcessPurchasesWithUpdates() {
        // Получаем созданного клиента и покупку
        Marketing_Report_Customer__c customer = [SELECT Id FROM Marketing_Report_Customer__c LIMIT 1];
        Marketing_Report_Purchase__c existingPurchase = [
            SELECT Id FROM Marketing_Report_Purchase__c 
            WHERE Marketing_Report_Customer__c = :customer.Id 
            LIMIT 1
        ];
        
        // Подготавливаем тестовый запрос с обновлением существующей покупки
        Map<String, Object> requestData = new Map<String, Object>{
            'customerId' => customer.Id,
            'budget' => 1500.00,
            'active' => false,
            'page' => 2,
            'totalPages' => 2,
            'purchases' => new List<Object>{
                new Map<String, Object>{
                    'Id' => existingPurchase.Id,
                    'Purchase_Amount__c' => 750.00,
                    'Date_Buy__c' => '2025-07-15',
                    'Month_Buy__c' => 7,
                    'Week_Buy__c' => 29
                }
            }
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/report-purchases/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(requestData));
        req.addHeader('Content-Type', 'application/json');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        ReportPurchasesController.processPurchases();
        
        Test.stopTest();
        
        // Проверяем ответ
        System.assertEquals(200, res.statusCode, 'Expected status code 200');
        
        // Проверяем что запись обновлена
        Marketing_Report_Purchase__c updatedPurchase = [
            SELECT Id, Purchase_Amount__c, Date_Buy__c, Month_Buy__c, Week_Buy__c
            FROM Marketing_Report_Purchase__c
            WHERE Id = :existingPurchase.Id
        ];
        
        System.assertEquals(750.00, updatedPurchase.Purchase_Amount__c, 'Purchase amount should be updated');
        System.assertEquals(Date.valueOf('2025-07-15'), updatedPurchase.Date_Buy__c, 'Date should be updated');
        System.assertEquals(29, updatedPurchase.Week_Buy__c, 'Week should be updated');
        
        // Проверяем что клиент обновлен (так как это последняя страница)
        Marketing_Report_Customer__c updatedCustomer = [
            SELECT Id, Budget__c, Active__c
            FROM Marketing_Report_Customer__c
            WHERE Id = :customer.Id
        ];
        
        System.assertEquals(1500.00, updatedCustomer.Budget__c, 'Customer budget should be updated');
        System.assertEquals(false, updatedCustomer.Active__c, 'Customer active status should be updated');
    }
    
    @isTest
    static void testGetRequest() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/report-purchases/';
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        ReportPurchasesController.getPurchaseInfo();
        
        Test.stopTest();
        
        // Проверяем ответ
        System.assertEquals(200, res.statusCode, 'Expected status code 200');
        System.assertNotEquals(null, res.responseBody, 'Response body should not be null');
        
        String responseString = res.responseBody.toString();
        System.assert(responseString.contains('ReportPurchasesController is active'), 
                     'Response should contain expected message');
    }
    
    @isTest
    static void testProcessPurchasesWithInvalidJson() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/report-purchases/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{invalid json}');
        req.addHeader('Content-Type', 'application/json');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        ReportPurchasesController.processPurchases();
        
        Test.stopTest();
        
        // Проверяем что возвращается ошибка
        System.assertEquals(500, res.statusCode, 'Expected status code 500 for invalid JSON');
        
        String responseString = res.responseBody.toString();
        System.assert(responseString.contains('error'), 'Response should contain error message');
    }
    
    @isTest
    static void testProcessPurchasesWithEmptyBody() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/report-purchases/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        ReportPurchasesController.processPurchases();
        
        Test.stopTest();
        
        // Проверяем что возвращается ошибка
        System.assertEquals(500, res.statusCode, 'Expected status code 500 for empty body');
    }
    
    @isTest
    static void testProcessPurchasesWithMissingCustomerId() {
        // Тестируем обработку запроса без customerId
        Map<String, Object> requestData = new Map<String, Object>{
            'budget' => 129.45,
            'active' => true,
            'page' => 1,
            'totalPages' => 1,
            'purchases' => new List<Object>()
        };
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.requestURI = '/services/apexrest/api/report-purchases/';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(requestData));
        req.addHeader('Content-Type', 'application/json');
        
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        
        ReportPurchasesController.processPurchases();
        
        Test.stopTest();
        
        // Проверяем что запрос обработан успешно даже без customerId
        System.assertEquals(200, res.statusCode, 'Expected status code 200');
    }
}
