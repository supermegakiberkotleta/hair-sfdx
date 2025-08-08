public with sharing class LicenseScanController {
    @AuraEnabled(cacheable=false)
    public static String scanLicence(String base64Data, String fileName, String endpointUrl) {
        try {
            System.debug('LicenseScanController.scanLicence called with:');
            System.debug('fileName: ' + fileName);
            System.debug('endpointUrl: ' + endpointUrl);
            System.debug('base64Data length: ' + (base64Data != null ? base64Data.length() : 0));
            
            if (String.isBlank(endpointUrl)) {
                throw new AuraHandledException('Endpoint URL is not configured. Please set the endpointUrl property in the component.');
            }
            if (String.isBlank(base64Data)) {
                throw new AuraHandledException('No file data provided for scanning.');
            }
            if (String.isBlank(fileName)) {
                throw new AuraHandledException('No file name provided for scanning.');
            }

            // Проверяем, что base64 данные корректны
            try {
                Blob testBlob = EncodingUtil.base64Decode(base64Data);
                System.debug('Base64 decode successful, blob size: ' + testBlob.size());
                
                // Проверяем размер файла (максимум 5MB)
                if (testBlob.size() > 5 * 1024 * 1024) {
                    throw new AuraHandledException('File size exceeds 5MB limit');
                }
            } catch (Exception decodeEx) {
                System.debug('Base64 decode failed: ' + decodeEx.getMessage());
                throw new AuraHandledException('Invalid base64 data provided: ' + decodeEx.getMessage());
            }

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('POST');
            request.setEndpoint(endpointUrl);
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(120000);
            
            // Build JSON payload with file data and name
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('fileData', base64Data);
            payload.put('fileName', fileName);
            
            String requestBody = JSON.serialize(payload);
            System.debug('Request body length: ' + requestBody.length());
            request.setBody(requestBody);

            System.debug('Sending request to: ' + endpointUrl);
            HttpResponse response = http.send(request);
            Integer statusCode = response.getStatusCode();
            System.debug('Response status code: ' + statusCode);
            
            if (statusCode < 200 || statusCode >= 300) {
                String snippet = response.getBody();
                if (snippet != null && snippet.length() > 500) {
                    snippet = snippet.substring(0, 500) + '...';
                }
                System.debug('Error response body: ' + snippet);
                throw new AuraHandledException('Scan service returned HTTP ' + statusCode + ': ' + snippet);
            }
            
            String responseBody = response.getBody();
            System.debug('Response body length: ' + (responseBody != null ? responseBody.length() : 0));
            
            if (String.isBlank(responseBody)) {
                throw new AuraHandledException('Empty response from scan service.');
            }
            
            Object parsed = JSON.deserializeUntyped(responseBody);
            if (!(parsed instanceof Map<String, Object>)) {
                throw new AuraHandledException('Unexpected response format from scan service.');
            }
            
            Map<String, Object> mapResponse = (Map<String, Object>) parsed;
            System.debug('Response keys: ' + mapResponse.keySet());
            
            // Accept either Name or name
            String nameValue = (String) (mapResponse.containsKey('Name') ? mapResponse.get('Name') : mapResponse.get('name'));
            if (String.isBlank(nameValue)) {
                throw new AuraHandledException('Scan completed, but Name was not present in the response.');
            }
            
            System.debug('Extracted name: ' + nameValue);
            return nameValue;
            
        } catch (System.CalloutException ex) {
            System.debug('CalloutException: ' + ex.getMessage());
            System.debug('CalloutException stack trace: ' + ex.getStackTraceString());
            throw new AuraHandledException('Callout failed: ' + ex.getMessage());
        } catch (AuraHandledException ex) {
            System.debug('AuraHandledException: ' + ex.getMessage());
            throw ex;
        } catch (Exception ex) {
            System.debug('Unexpected Exception: ' + ex.getMessage());
            System.debug('Exception type: ' + ex.getTypeName());
            System.debug('Exception stack trace: ' + ex.getStackTraceString());
            throw new AuraHandledException('Unexpected error: ' + ex.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static String testConnection(String endpointUrl) {
        try {
            System.debug('Testing connection to: ' + endpointUrl);
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setEndpoint(endpointUrl);
            request.setTimeout(30000);
            
            HttpResponse response = http.send(request);
            Integer statusCode = response.getStatusCode();
            System.debug('Test response status: ' + statusCode);
            
            if (statusCode >= 200 && statusCode < 300) {
                return 'Connection successful. Status: ' + statusCode;
            } else {
                return 'Connection failed. Status: ' + statusCode + ' - ' + response.getBody();
            }
        } catch (Exception ex) {
            System.debug('Test connection error: ' + ex.getMessage());
            return 'Connection error: ' + ex.getMessage();
        }
    }
} 