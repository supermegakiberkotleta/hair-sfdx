public with sharing class AutodialCampaignApiController {
    
    private static final String NAMED_CREDENTIAL = 'Telephony_Credential';
    private static final String API_BASE_PATH = '/api/v1/autodial-campaign';
    
    @AuraEnabled
    public static ApiResponse startCampaign(String campaignId) {
        return executeApiCall(campaignId, 'start');
    }
    
    @AuraEnabled
    public static ApiResponse pauseCampaign(String campaignId) {
        return executeApiCall(campaignId, 'pause');
    }
    
    @AuraEnabled
    public static ApiResponse cancelCampaign(String campaignId) {
        return executeApiCall(campaignId, 'cancel');
    }
    
    @AuraEnabled
    public static ApiResponse completeCampaign(String campaignId) {
        return executeApiCall(campaignId, 'complete');
    }
    
    private static ApiResponse executeApiCall(String campaignId, String action) {
        try {
            HttpRequest req = new HttpRequest();
            String endpoint = 'callout:' + NAMED_CREDENTIAL + API_BASE_PATH + '/' + action;
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            
            Map<String, String> requestBody = new Map<String, String>();
            requestBody.put('salesforce_id', campaignId);
            req.setBody(JSON.serialize(requestBody));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            ApiResponse response = new ApiResponse();
            response.statusCode = res.getStatusCode();
            response.body = res.getBody();
            
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            response.status = (String) responseMap.get('status');
            response.message = (String) responseMap.get('message');
            
            if (res.getStatusCode() == 200) {
                response.success = true;
            } else {
                response.success = false;
            }
            
            return response;
            
        } catch (Exception e) {
            ApiResponse errorResponse = new ApiResponse();
            errorResponse.success = false;
            errorResponse.statusCode = 500;
            errorResponse.status = 'error';
            errorResponse.message = 'Ошибка: ' + e.getMessage();
            return errorResponse;
        }
    }
    
    public class ApiResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String status;
        @AuraEnabled public String message;
        @AuraEnabled public String body;
    }
}

