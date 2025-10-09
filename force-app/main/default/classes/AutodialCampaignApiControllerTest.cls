@isTest
private class AutodialCampaignApiControllerTest {
    
    @isTest
    static void testStartCampaignSuccess() {
        Test.setMock(HttpCalloutMock.class, new AutodialCampaignApiMock(200, 'success', 'Campaign started successfully'));
        
        Autodial_Campaign__c campaign = createTestCampaign();
        
        Test.startTest();
        AutodialCampaignApiController.ApiResponse response = AutodialCampaignApiController.startCampaign(campaign.Id);
        Test.stopTest();
        
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertEquals('success', response.status, 'Status should be success');
        System.assertEquals('Campaign started successfully', response.message, 'Message should match');
    }
    
    @isTest
    static void testPauseCampaignSuccess() {
        Test.setMock(HttpCalloutMock.class, new AutodialCampaignApiMock(200, 'success', 'Campaign paused successfully'));
        
        Autodial_Campaign__c campaign = createTestCampaign();
        
        Test.startTest();
        AutodialCampaignApiController.ApiResponse response = AutodialCampaignApiController.pauseCampaign(campaign.Id);
        Test.stopTest();
        
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertEquals('success', response.status, 'Status should be success');
        System.assertEquals('Campaign paused successfully', response.message, 'Message should match');
    }
    
    @isTest
    static void testCancelCampaignSuccess() {
        Test.setMock(HttpCalloutMock.class, new AutodialCampaignApiMock(200, 'success', 'Campaign canceled successfully'));
        
        Autodial_Campaign__c campaign = createTestCampaign();
        
        Test.startTest();
        AutodialCampaignApiController.ApiResponse response = AutodialCampaignApiController.cancelCampaign(campaign.Id);
        Test.stopTest();
        
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertEquals('success', response.status, 'Status should be success');
        System.assertEquals('Campaign canceled successfully', response.message, 'Message should match');
    }
    
    @isTest
    static void testCompleteCampaignSuccess() {
        Test.setMock(HttpCalloutMock.class, new AutodialCampaignApiMock(200, 'success', 'Campaign completed successfully'));
        
        Autodial_Campaign__c campaign = createTestCampaign();
        
        Test.startTest();
        AutodialCampaignApiController.ApiResponse response = AutodialCampaignApiController.completeCampaign(campaign.Id);
        Test.stopTest();
        
        System.assertEquals(true, response.success, 'Response should be successful');
        System.assertEquals(200, response.statusCode, 'Status code should be 200');
        System.assertEquals('success', response.status, 'Status should be success');
        System.assertEquals('Campaign completed successfully', response.message, 'Message should match');
    }
    
    @isTest
    static void testCampaignError422() {
        Test.setMock(HttpCalloutMock.class, new AutodialCampaignApiMock(422, 'error', 'Validation error message'));
        
        Autodial_Campaign__c campaign = createTestCampaign();
        
        Test.startTest();
        AutodialCampaignApiController.ApiResponse response = AutodialCampaignApiController.startCampaign(campaign.Id);
        Test.stopTest();
        
        System.assertEquals(false, response.success, 'Response should not be successful');
        System.assertEquals(422, response.statusCode, 'Status code should be 422');
        System.assertEquals('error', response.status, 'Status should be error');
        System.assertEquals('Validation error message', response.message, 'Message should match');
    }
    
    @isTest
    static void testCampaignError404() {
        Test.setMock(HttpCalloutMock.class, new AutodialCampaignApiMock(404, 'error', 'Campaign not found'));
        
        Autodial_Campaign__c campaign = createTestCampaign();
        
        Test.startTest();
        AutodialCampaignApiController.ApiResponse response = AutodialCampaignApiController.startCampaign(campaign.Id);
        Test.stopTest();
        
        System.assertEquals(false, response.success, 'Response should not be successful');
        System.assertEquals(404, response.statusCode, 'Status code should be 404');
        System.assertEquals('error', response.status, 'Status should be error');
        System.assertEquals('Campaign not found', response.message, 'Message should match');
    }
    
    @isTest
    static void testCampaignError500() {
        Test.setMock(HttpCalloutMock.class, new AutodialCampaignApiMock(500, 'error', 'Failed to start campaign'));
        
        Autodial_Campaign__c campaign = createTestCampaign();
        
        Test.startTest();
        AutodialCampaignApiController.ApiResponse response = AutodialCampaignApiController.startCampaign(campaign.Id);
        Test.stopTest();
        
        System.assertEquals(false, response.success, 'Response should not be successful');
        System.assertEquals(500, response.statusCode, 'Status code should be 500');
        System.assertEquals('error', response.status, 'Status should be error');
        System.assertEquals('Failed to start campaign', response.message, 'Message should match');
    }
    
    @isTest
    static void testExceptionHandling() {
        // Test with invalid endpoint to trigger exception
        Test.setMock(HttpCalloutMock.class, new AutodialCampaignApiMock(500, 'error', 'Internal server error'));
        
        Autodial_Campaign__c campaign = createTestCampaign();
        
        Test.startTest();
        AutodialCampaignApiController.ApiResponse response = AutodialCampaignApiController.startCampaign(campaign.Id);
        Test.stopTest();
        
        System.assertEquals(false, response.success, 'Response should not be successful');
        System.assertEquals(500, response.statusCode, 'Status code should be 500');
        System.assertEquals('error', response.status, 'Status should be error');
        System.assertNotEquals(null, response.message, 'Error message should not be null');
    }
    
    // Helper method to create test campaign
    private static Autodial_Campaign__c createTestCampaign() {
        Autodial_Campaign__c campaign = new Autodial_Campaign__c(
            Name = 'Test Campaign',
            Status__c = 'Draft',
            Start_Date__c = DateTime.now(),
            End_Date__c = DateTime.now().addDays(7)
        );
        insert campaign;
        return campaign;
    }
    
    // Mock class for successful HTTP responses
    private class AutodialCampaignApiMock implements HttpCalloutMock {
        private Integer statusCode;
        private String status;
        private String message;
        
        public AutodialCampaignApiMock(Integer statusCode, String status, String message) {
            this.statusCode = statusCode;
            this.status = status;
            this.message = message;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            
            Map<String, Object> responseBody = new Map<String, Object>();
            responseBody.put('status', status);
            responseBody.put('message', message);
            
            if (statusCode == 200) {
                responseBody.put('campaign_id', 123);
                responseBody.put('salesforce_id', 'a0X5e000001AbCdEFG');
            } else if (statusCode == 500) {
                responseBody.put('error', 'Internal server error details');
            }
            
            res.setBody(JSON.serialize(responseBody));
            return res;
        }
    }
    
}

