@IsTest
private class LicenseScanControllerTest {
    private class SuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
           
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Name":"John Doe"}');
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
        String nameValue = LicenseScanController.scanLicence('base64data', 'callout:dummy');
        Test.stopTest();
    }

    @IsTest
    static void testErrorScan() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        try {
            Test.startTest();
            LicenseScanController.scanLicence('base64data', 'callout:dummy');
        } catch (AuraHandledException ex) {
        } finally {
            Test.stopTest();
        }
    }

    @IsTest
    static void testValidation() {
        try {
            LicenseScanController.scanLicence('', '');
        } catch (AuraHandledException ex) {
        }
    }
} 