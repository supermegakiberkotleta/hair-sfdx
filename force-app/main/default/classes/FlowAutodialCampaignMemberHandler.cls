public with sharing class FlowAutodialCampaignMemberHandler {
    
    /**
     * Flow-accessible method to add campaign members
     * @param recordIds List of record IDs to add to campaign
     * @param objectType Type of object (Lead, Contact, or Account)
     * @param autodialId ID of the Autodial Campaign
     * @param useBatchProcessing Whether to use batch processing for large volumes
     * @return String Success message
     */
    @InvocableMethod(label='Add Campaign Members' description='Adds records to Autodial Campaign Members with optional batch processing for large volumes')
    public static List<String> addCampaignMembers(List<CampaignMemberRequest> requests) {
        List<String> results = new List<String>();
        
        for (CampaignMemberRequest request : requests) {
            try {
                String result;
                if (request.useBatchProcessing == true) {
                    result = processCampaignMemberRequestBatch(request);
                } else {
                    result = processCampaignMemberRequest(request);
                }
                results.add(result);
            } catch (Exception e) {
                results.add('Error: ' + e.getMessage());
            }
        }
        
        return results;
    }
    
    /**
     * Processes a single campaign member request
     */
    private static String processCampaignMemberRequest(CampaignMemberRequest request) {
        // Validate input parameters
        if (request.recordIds == null || request.recordIds.isEmpty()) {
            return 'Error: No record IDs provided';
        }
        
        if (String.isBlank(request.objectType)) {
            return 'Error: Object type is required';
        }
        
        if (String.isBlank(request.autodialId)) {
            return 'Error: Autodial Campaign ID is required';
        }
        
        // Validate object type
        String objectType = request.objectType.toLowerCase();
        if (objectType != 'lead' && objectType != 'contact' && objectType != 'account') {
            return 'Error: Invalid object type. Must be Lead, Contact, or Account';
        }
        
        // Validate autodial campaign exists
        List<Autodial_Campaign__c> campaigns = [
            SELECT Id, Name 
            FROM Autodial_Campaign__c 
            WHERE Id = :request.autodialId 
            LIMIT 1
        ];
        
        if (campaigns.isEmpty()) {
            return 'Error: Autodial Campaign not found';
        }
        
        // Process the records
        return processRecords(request.recordIds, objectType, request.autodialId);
    }
    
    /**
     * Processes records and creates campaign members with batch processing
     */
    private static String processRecords(List<String> recordIds, String objectType, String autodialId) {
        Set<Id> ids = new Set<Id>();
        
        // Convert string IDs to Id type and validate
        for (String recordId : recordIds) {
            try {
                Id idValue = Id.valueOf(recordId);
                ids.add(idValue);
            } catch (Exception e) {
                return 'Error: Invalid record ID format: ' + recordId;
            }
        }
        
        // Check for existing records to avoid duplicates
        Set<Id> existingIds = getExistingRecordIds(ids, objectType, autodialId);
        
        // Filter out existing records
        Set<Id> newIds = new Set<Id>();
        for (Id idValue : ids) {
            if (!existingIds.contains(idValue)) {
                newIds.add(idValue);
            }
        }
        
        if (newIds.isEmpty()) {
            return 'Success: All records already exist in the campaign';
        }
        
        // Process in batches to avoid governor limits
        return processRecordsInBatches(newIds, objectType, autodialId, ids.size() - newIds.size());
    }
    
    /**
     * Processes records in batches to avoid governor limits
     */
    private static String processRecordsInBatches(Set<Id> newIds, String objectType, String autodialId, Integer skippedCount) {
        List<Id> idList = new List<Id>(newIds);
        Integer batchSize = 200; // Salesforce DML limit
        Integer totalProcessed = 0;
        Integer totalErrors = 0;
        List<String> errorMessages = new List<String>();
        
        for (Integer i = 0; i < idList.size(); i += batchSize) {
            Integer endIndex = Math.min(i + batchSize, idList.size());
            List<Id> batchIds = new List<Id>();
            
            for (Integer j = i; j < endIndex; j++) {
                batchIds.add(idList[j]);
            }
            
            try {
                List<SObject> campaignMembers = createCampaignMemberRecords(new Set<Id>(batchIds), objectType, autodialId);
                
                if (!campaignMembers.isEmpty()) {
                    insert campaignMembers;
                    totalProcessed += campaignMembers.size();
                }
            } catch (Exception e) {
                totalErrors++;
                errorMessages.add('Batch ' + (i/batchSize + 1) + ': ' + e.getMessage());
                
                // If we have too many errors, stop processing
                if (totalErrors > 5) {
                    break;
                }
            }
        }
        
        if (totalErrors > 0) {
            String errorSummary = 'Partial success: Added ' + totalProcessed + ' member(s); ' + totalErrors + ' batch(es) failed. Errors: ' + String.join(errorMessages, '; ');
            return errorSummary;
        }
        
        return 'Success: Added ' + totalProcessed + ' member(s); skipped ' + skippedCount + ' existing record(s)';
    }
    
    /**
     * Gets existing record IDs to avoid duplicates
     */
    private static Set<Id> getExistingRecordIds(Set<Id> recordIds, String objectType, String autodialId) {
        Set<Id> existingIds = new Set<Id>();
        
        String fieldName = getFieldName(objectType);
        if (String.isBlank(fieldName)) {
            return existingIds;
        }
        
        String query = 'SELECT ' + fieldName + ' FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :autodialId AND ' + fieldName + ' IN :recordIds';
        
        try {
            for (SObject record : Database.query(query)) {
                Id recordId = (Id)record.get(fieldName);
                if (recordId != null) {
                    existingIds.add(recordId);
                }
            }
        } catch (Exception e) {
            System.debug('Error querying existing records: ' + e.getMessage());
        }
        
        return existingIds;
    }
    
    /**
     * Gets the field name based on object type
     */
    private static String getFieldName(String objectType) {
        switch on objectType.toLowerCase() {
            when 'lead' {
                return 'Lead__c';
            }
            when 'contact' {
                return 'Contact__c';
            }
            when 'account' {
                return 'Account__c';
            }
            when else {
                return null;
            }
        }
    }
    
    /**
     * Creates campaign member records with additional data from source records
     */
    private static List<SObject> createCampaignMemberRecords(Set<Id> recordIds, String objectType, String autodialId) {
        List<SObject> campaignMembers = new List<SObject>();
        String fieldName = getFieldName(objectType);
        
        if (String.isBlank(fieldName)) {
            return campaignMembers;
        }
        
        Schema.SObjectType campaignMemberType = Schema.getGlobalDescribe().get('Autodial_CampaignMembers__c');
        if (campaignMemberType == null) {
            return campaignMembers;
        }
        
        // Get field references
        Schema.SObjectField campaignField = campaignMemberType.getDescribe().fields.getMap().get('Autodial_Campaign__c');
        Schema.SObjectField recordField = campaignMemberType.getDescribe().fields.getMap().get(fieldName);
        Schema.SObjectField nameField = campaignMemberType.getDescribe().fields.getMap().get('Name');
        Schema.SObjectField phoneField = campaignMemberType.getDescribe().fields.getMap().get('Phone__c');
        Schema.SObjectField recordTypeField = campaignMemberType.getDescribe().fields.getMap().get('Record_Type__c');
        Schema.SObjectField recordIdField = campaignMemberType.getDescribe().fields.getMap().get('Record__c');
        
        // Query source records to get additional data
        Map<Id, SObject> sourceRecords = getSourceRecords(recordIds, objectType);
        
        for (Id recordId : recordIds) {
            SObject campaignMember = campaignMemberType.newSObject();
            campaignMember.put(campaignField, autodialId);
            campaignMember.put(recordField, recordId);
            
            // Set additional fields
            if (recordIdField != null) {
                String recordUrl = buildRecordUrl(recordId, objectType);
                campaignMember.put(recordIdField, recordUrl);
            }
            
            if (recordTypeField != null) {
                campaignMember.put(recordTypeField, objectType);
            }
            
            // Get data from source record
            SObject sourceRecord = sourceRecords.get(recordId);
            if (sourceRecord != null) {
                // Set Name field (Last Name for Lead/Contact, Name for Account)
                if (nameField != null) {
                    String nameValue = getNameFromSourceRecord(sourceRecord, objectType);
                    if (String.isNotBlank(nameValue)) {
                        campaignMember.put(nameField, nameValue);
                    }
                }
                
                // Set Phone field
                if (phoneField != null) {
                    String phoneValue = getPhoneFromSourceRecord(sourceRecord, objectType);
                    if (String.isNotBlank(phoneValue)) {
                        campaignMember.put(phoneField, phoneValue);
                    }
                }
            }
            
            campaignMembers.add(campaignMember);
        }
        
        return campaignMembers;
    }
    
    /**
     * Queries source records to get additional data
     */
    private static Map<Id, SObject> getSourceRecords(Set<Id> recordIds, String objectType) {
        Map<Id, SObject> sourceRecords = new Map<Id, SObject>();
        
        if (recordIds.isEmpty()) {
            return sourceRecords;
        }
        
        try {
            String soql = buildSourceRecordsQuery(objectType, recordIds);
            if (String.isNotBlank(soql)) {
                List<SObject> records = Database.query(soql);
                for (SObject record : records) {
                    sourceRecords.put(record.Id, record);
                }
            }
        } catch (Exception e) {
            System.debug('Error querying source records: ' + e.getMessage());
        }
        
        return sourceRecords;
    }
    
    /**
     * Builds SOQL query for source records based on object type
     */
    private static String buildSourceRecordsQuery(String objectType, Set<Id> recordIds) {
        switch on objectType.toLowerCase() {
            when 'lead' {
                return 'SELECT Id, LastName, FirstName, Phone FROM Lead WHERE Id IN :recordIds';
            }
            when 'contact' {
                return 'SELECT Id, LastName, FirstName, Phone FROM Contact WHERE Id IN :recordIds';
            }
            when 'account' {
                return 'SELECT Id, Name, Phone FROM Account WHERE Id IN :recordIds';
            }
            when else {
                return null;
            }
        }
    }
    
    /**
     * Gets name value from source record based on object type
     */
    private static String getNameFromSourceRecord(SObject sourceRecord, String objectType) {
        switch on objectType.toLowerCase() {
            when 'lead' {
                String firstName = (String)sourceRecord.get('FirstName');
                String lastName = (String)sourceRecord.get('LastName');
                if (String.isNotBlank(lastName)) {
                    return String.isNotBlank(firstName) ? firstName + ' ' + lastName : lastName;
                }
                return firstName;
            }
            when 'contact' {
                String firstName = (String)sourceRecord.get('FirstName');
                String lastName = (String)sourceRecord.get('LastName');
                if (String.isNotBlank(lastName)) {
                    return String.isNotBlank(firstName) ? firstName + ' ' + lastName : lastName;
                }
                return firstName;
            }
            when 'account' {
                return (String)sourceRecord.get('Name');
            }
            when else {
                return null;
            }
        }
    }
    
    /**
     * Gets phone value from source record
     */
    private static String getPhoneFromSourceRecord(SObject sourceRecord, String objectType) {
        return (String)sourceRecord.get('Phone');
    }
    
    /**
     * Builds Lightning URL for the record
     */
    private static String buildRecordUrl(Id recordId, String objectType) {
        if (recordId == null) {
            return null;
        }
        
        // Get the org domain URL
        String orgDomain = URL.getOrgDomainUrl().toExternalForm();
        
        // Build the Lightning URL based on object type
        String objectApiName = getObjectApiName(objectType);
        if (String.isBlank(objectApiName)) {
            return null;
        }
        
        return orgDomain + '/lightning/r/' + objectApiName + '/' + recordId + '/view';
    }
    
    /**
     * Gets object API name based on object type
     */
    private static String getObjectApiName(String objectType) {
        switch on objectType.toLowerCase() {
            when 'lead' {
                return 'Lead';
            }
            when 'contact' {
                return 'Contact';
            }
            when 'account' {
                return 'Account';
            }
            when else {
                return null;
            }
        }
    }
    
    /**
     * Processes a single campaign member request using batch processing
     */
    private static String processCampaignMemberRequestBatch(CampaignMemberRequest request) {
        // Validate input parameters
        if (request.recordIds == null || request.recordIds.isEmpty()) {
            return 'Error: No record IDs provided';
        }
        
        if (String.isBlank(request.objectType)) {
            return 'Error: Object type is required';
        }
        
        if (String.isBlank(request.autodialId)) {
            return 'Error: Autodial Campaign ID is required';
        }
        
        // Validate object type
        String objectType = request.objectType.toLowerCase();
        if (objectType != 'lead' && objectType != 'contact' && objectType != 'account') {
            return 'Error: Invalid object type. Must be Lead, Contact, or Account';
        }
        
        // Validate autodial campaign exists
        List<Autodial_Campaign__c> campaigns = [
            SELECT Id, Name 
            FROM Autodial_Campaign__c 
            WHERE Id = :request.autodialId 
            LIMIT 1
        ];
        
        if (campaigns.isEmpty()) {
            return 'Error: Autodial Campaign not found';
        }
        
        // For very large volumes (>1000), use batch processing
        if (request.recordIds.size() > 1000) {
            return processRecordsWithBatch(request.recordIds, objectType, request.autodialId);
        } else {
            // Use regular batch processing for medium volumes
            return processRecordsInBatches(convertToIdSet(request.recordIds), objectType, request.autodialId, 0);
        }
    }
    
    /**
     * Converts string IDs to Id set with validation
     */
    private static Set<Id> convertToIdSet(List<String> recordIds) {
        Set<Id> ids = new Set<Id>();
        
        for (String recordId : recordIds) {
            try {
                Id idValue = Id.valueOf(recordId);
                ids.add(idValue);
            } catch (Exception e) {
                // Skip invalid IDs and log error
                System.debug('Invalid record ID format: ' + recordId + ' - ' + e.getMessage());
            }
        }
        
        return ids;
    }
    
    /**
     * Processes very large volumes using batch processing
     */
    private static String processRecordsWithBatch(List<String> recordIds, String objectType, String autodialId) {
        try {
            // Create campaign member records first
            Set<Id> ids = convertToIdSet(recordIds);
            
            if (ids.isEmpty()) {
                return 'Error: No valid record IDs provided';
            }
            
            // Check for existing records to avoid duplicates
            Set<Id> existingIds = getExistingRecordIds(ids, objectType, autodialId);
            
            // Filter out existing records
            Set<Id> newIds = new Set<Id>();
            for (Id idValue : ids) {
                if (!existingIds.contains(idValue)) {
                    newIds.add(idValue);
                }
            }
            
            if (newIds.isEmpty()) {
                return 'Success: All records already exist in the campaign';
            }
            
            // Create campaign member records
            List<SObject> campaignMembers = createCampaignMemberRecords(newIds, objectType, autodialId);
            
            if (campaignMembers.isEmpty()) {
                return 'Success: No new records to add';
            }
            
            // Insert records
            insert campaignMembers;
            
            // Start batch processing for callouts (skip in test context)
            if (!Test.isRunningTest()) {
                Database.executeBatch(new AutodialCampaignMembersBatch(new Map<Id, SObject>(campaignMembers).keySet()), 50);
            }
            
            Integer skippedCount = ids.size() - newIds.size();
            String message = 'Success: Added ' + campaignMembers.size() + ' member(s); skipped ' + skippedCount + ' existing record(s)';
            if (!Test.isRunningTest()) {
                message += '. Batch processing started for external API calls.';
            }
            return message;
            
        } catch (Exception e) {
            return 'Error: Failed to process records - ' + e.getMessage();
        }
    }
    
    /**
     * Input class for Flow
     */
    public class CampaignMemberRequest {
        @InvocableVariable(label='Record IDs' description='List of record IDs to add to campaign' required=true)
        public List<String> recordIds;
        
        @InvocableVariable(label='Object Type' description='Type of object (Lead, Contact, or Account)' required=true)
        public String objectType;
        
        @InvocableVariable(label='Autodial Campaign ID' description='ID of the Autodial Campaign' required=true)
        public String autodialId;
        
        @InvocableVariable(label='Use Batch Processing' description='Whether to use batch processing for large volumes (recommended for 50+ records)' required=false)
        public Boolean useBatchProcessing;
    }
}