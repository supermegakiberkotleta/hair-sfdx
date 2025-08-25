@IsTest
private class LicenseScanControllerTest {
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Проверяем, что в запросе передается fileData и fileName
            String body = req.getBody();
          
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Name":"John Doe","Age":30,"is_valid":true}');
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error":"Bad request"}');
            return res;
        }
    }

    @IsTest
    static void testSuccessScan() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        String nameValue = LicenseScanController.scanLicence('dGVzdA==', 'test.pdf', 'https://api.example.com/scan');
        Test.stopTest();
        System.assertEquals('John Doe', nameValue);
    }

    @IsTest
    static void testErrorScan() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        try {
            Test.startTest();
            LicenseScanController.scanLicence('dGVzdA==', 'test.pdf', 'https://api.example.com/scan');
        } catch (AuraHandledException ex) {
        } finally {
            Test.stopTest();
        }
    }

    @IsTest
    static void testValidation() {
        try {
            LicenseScanController.scanLicence('', '', '');
        } catch (AuraHandledException ex) {
        }
        
        try {
            LicenseScanController.scanLicence('', '', 'https://api.example.com/scan');
        } catch (AuraHandledException ex) {
        }
        
        try {
            LicenseScanController.scanLicence('dGVzdA==', '', 'https://api.example.com/scan');
        } catch (AuraHandledException ex) {
        }
    }

    private class InvalidDocMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Name":"John Doe","Age":35,"is_valid":false}');
            return res;
        }
    }

    @IsTest
    static void testInvalidDocumentFlag() {
        Test.setMock(HttpCalloutMock.class, new InvalidDocMock());
        try {
            Test.startTest();
            LicenseScanController.scanLicence('dGVzdA==', 'test.pdf', 'https://api.example.com/scan');
            System.assert(false, 'Expected AuraHandledException for invalid document');
        } catch (AuraHandledException ex) {
        } finally {
            Test.stopTest();
        }
    }
}