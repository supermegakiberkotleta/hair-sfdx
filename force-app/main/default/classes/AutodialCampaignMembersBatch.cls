public with sharing class AutodialCampaignMembersBatch implements Database.Batchable<Id>, Database.AllowsCallouts {
    
    private Set<Id> recordIds;
    private String operation;
    
    public AutodialCampaignMembersBatch(Set<Id> recordIds) {
        this.recordIds = recordIds;
        this.operation = 'create';
    }
    
    public AutodialCampaignMembersBatch(Set<Id> recordIds, String operation) {
        this.recordIds = recordIds;
        this.operation = operation;
    }
    
    public Iterable<Id> start(Database.BatchableContext bc) {
        return new List<Id>(recordIds);
    }
    
    public void execute(Database.BatchableContext bc, List<Id> scope) {
        if (operation == 'create') {
            processCreate(scope);
        } else if (operation == 'update') {
            processUpdate(scope);
        } else if (operation == 'delete') {
            processDelete(scope);
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        // Optional: Add any cleanup or notification logic here
        System.debug('AutodialCampaignMembersBatch completed for operation: ' + operation);
    }
    
    private void processCreate(List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) return;
        
        // Get all accessible fields
        List<String> fieldApiNames = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = Autodial_CampaignMembers__c.SObjectType.getDescribe().fields.getMap();
        for (String apiName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fDesc = fieldMap.get(apiName).getDescribe();
            if (fDesc.isAccessible()) {
                fieldApiNames.add(apiName);
            }
        }
        
        String soql = 'SELECT ' + String.join(fieldApiNames, ',') + ' FROM Autodial_CampaignMembers__c WHERE Id IN :recordIds';
        List<Autodial_CampaignMembers__c> records = Database.query(soql);
        
        // Process records in smaller chunks to avoid callout limits
        Integer chunkSize = 10; // Process 10 records at a time
        for (Integer i = 0; i < records.size(); i += chunkSize) {
            Integer endIndex = Math.min(i + chunkSize, records.size());
            List<Autodial_CampaignMembers__c> chunk = new List<Autodial_CampaignMembers__c>();
            
            for (Integer j = i; j < endIndex; j++) {
                chunk.add(records[j]);
            }
            
            processChunk(chunk);
        }
    }
    
    private void processUpdate(List<Id> recordIds) {
        // Implementation for update operation
        // This would be similar to processCreate but for updates
    }
    
    private void processDelete(List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) return;
        
        for (Id recId : recordIds) {
            Map<String, Object> payload = new Map<String, Object>{ 'Id' => recId };
            performPost('/api/v1/autodial-campaign-member/delete', payload);
        }
    }
    
    private void processChunk(List<Autodial_CampaignMembers__c> records) {
        for (Autodial_CampaignMembers__c rec : records) {
            Map<String, Object> payload = buildAllFieldsPayload(rec);
            performPost('/api/v1/autodial-campaign-member/create', payload);
        }
    }
    
    private void performPost(String relativePath, Map<String, Object> payload) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String base = 'callout:Telephony_Credential';
        String path = (relativePath != null && relativePath.startsWith('/')) ? relativePath : ('/' + String.valueOf(relativePath));
        req.setEndpoint(base + path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
        
        try {
            HttpResponse response = http.send(req);
            if (response.getStatusCode() != 200) {
                System.debug('HTTP Error: ' + response.getStatusCode() + ' - ' + response.getBody());
            }
        } catch (Exception e) {
            System.debug('Callout Error: ' + e.getMessage());
        }
    }
    
    private Map<String, Object> buildAllFieldsPayload(SObject sobj) {
        Map<String, Object> payload = new Map<String, Object>();
        if (sobj == null) return payload;
        Map<String, Object> populated = sobj.getPopulatedFieldsAsMap();
        if (populated != null && !populated.isEmpty()) {
            payload.putAll(populated);
        }
        return payload;
    }
}