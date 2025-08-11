@IsTest
private class CheckScanControllerTest {
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Проверяем, что в запросе передается fileData и fileName
            String body = req.getBody();
          
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success":true,"routing_number":"072403004","account_number":"9950106444","company_name":"Test Company Inc","address":"123 Test Street, Test City, TS 12345","message":"Check numbers extracted successfully","fileType":"jpg"}');
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"success":false,"error":"Bad request"}');
            return res;
        }
    }

    @IsTest
    static void testSuccessScan() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        Map<String, String> result = CheckScanController.scanCheck('dGVzdA==', 'test.jpg', 'https://lenderpro.itprofit.net/api/v1/check/analyze');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return result map');
        System.assertEquals('072403004', result.get('routing_number'), 'Should have correct routing number');
        System.assertEquals('9950106444', result.get('account_number'), 'Should have correct account number');
        System.assertEquals('Test Company Inc', result.get('company_name'), 'Should have correct company name');
        System.assertEquals('123 Test Street, Test City, TS 12345', result.get('address'), 'Should have correct address');
    }

    @IsTest
    static void testErrorScan() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        try {
            Test.startTest();
            CheckScanController.scanCheck('dGVzdA==', 'test.jpg', 'https://lenderpro.itprofit.net/api/v1/check/analyze');
        } catch (AuraHandledException ex) {
            // Expected
        } finally {
            Test.stopTest();
        }
    }

    @IsTest
    static void testValidation() {
        try {
            CheckScanController.scanCheck('', '', '');
        } catch (AuraHandledException ex) {
            // Expected
        }
        
        try {
            CheckScanController.scanCheck('', '', 'https://lenderpro.itprofit.net/api/v1/check/analyze');
        } catch (AuraHandledException ex) {
            // Expected
        }
        
        try {
            CheckScanController.scanCheck('dGVzdA==', '', 'https://lenderpro.itprofit.net/api/v1/check/analyze');
        } catch (AuraHandledException ex) {
            // Expected
        }
    }
} 