public with sharing class LicenseScanController {
    @AuraEnabled(cacheable=false)
    public static String scanLicence(String base64Image, String endpointUrl) {
        if (String.isBlank(endpointUrl)) {
            throw new AuraHandledException('Endpoint URL is not configured. Please set the endpointUrl property in the component.');
        }
        if (String.isBlank(base64Image)) {
            throw new AuraHandledException('No image provided for scanning.');
        }

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(endpointUrl);
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(120000);
        // Build a simple JSON payload { "image": "BASE64" }
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('image', base64Image);
        request.setBody(JSON.serialize(payload));

        try {
            HttpResponse response = http.send(request);
            Integer statusCode = response.getStatusCode();
            if (statusCode < 200 || statusCode >= 300) {
                String snippet = response.getBody();
                if (snippet != null && snippet.length() > 500) {
                    snippet = snippet.substring(0, 500) + '...';
                }
                throw new AuraHandledException('Scan service returned HTTP ' + statusCode + ': ' + snippet);
            }
            String responseBody = response.getBody();
            if (String.isBlank(responseBody)) {
                throw new AuraHandledException('Empty response from scan service.');
            }
            Object parsed = JSON.deserializeUntyped(responseBody);
            if (!(parsed instanceof Map<String, Object>)) {
                throw new AuraHandledException('Unexpected response format from scan service.');
            }
            Map<String, Object> mapResponse = (Map<String, Object>) parsed;
            // Accept either Name or name
            String nameValue = (String) (mapResponse.containsKey('Name') ? mapResponse.get('Name') : mapResponse.get('name'));
            if (String.isBlank(nameValue)) {
                throw new AuraHandledException('Scan completed, but Name was not present in the response.');
            }
            return nameValue;
        } catch (System.CalloutException ex) {
            throw new AuraHandledException('Callout failed: ' + ex.getMessage());
        } catch (Exception ex) {
            throw new AuraHandledException('Unexpected error: ' + ex.getMessage());
        }
    }
} 