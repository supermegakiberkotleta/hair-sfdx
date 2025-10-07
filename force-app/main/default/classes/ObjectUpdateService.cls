/**
 * @description Service for updating objects by parameters through Flow
 * @author QueueHair Team
 * @date 2024
 */
public with sharing class ObjectUpdateService {
    
    /**
     * @description Input parameters for Flow
     */
    public class UpdateRequest {
        @InvocableVariable(label='Collection of Record IDs' description='Collection of record IDs to update' required=true)
        public List<String> recordIds;
        
        @InvocableVariable(label='Object Type' description='Object type (e.g.: Lead, Account, Contact)' required=true)
        public String objectType;
        
        @InvocableVariable(label='Fields JSON' description='JSON string with fields and values to update' required=true)
        public String fieldsJson;
    }
    
    /**
     * @description Update operation result
     */
    public class UpdateResult {
        @InvocableVariable(label='Success' description='Operation success')
        public Boolean success;
        
        @InvocableVariable(label='Message' description='Result message')
        public String message;
        
        @InvocableVariable(label='Updated Records Count' description='Number of updated records')
        public Integer updatedRecordsCount;
        
        @InvocableVariable(label='Error Details' description='Error details')
        public String errorDetails;
    }
    
    // Constants for batch processing threshold
    private static final Integer BATCH_THRESHOLD = 50;
    private static final Integer MAX_SYNC_RECORDS = 200;
    
    /**
     * @description Method for calling from Flow
     * @param requests List of update requests
     * @return List of update results
     */
    @InvocableMethod(label='Update Objects by Parameters' description='Updates objects by passed parameters')
    public static List<UpdateResult> updateObjects(List<UpdateRequest> requests) {
        List<UpdateResult> results = new List<UpdateResult>();
        
        for (UpdateRequest request : requests) {
            UpdateResult result = new UpdateResult();
            result.success = false;
            result.updatedRecordsCount = 0;
            
            try {
                // Input parameters validation
                if (String.isBlank(request.objectType) || String.isBlank(request.fieldsJson) || 
                    request.recordIds == null || request.recordIds.isEmpty()) {
                    result.message = 'Not all required parameters are filled';
                    result.errorDetails = 'objectType, fieldsJson and recordIds are required';
                    results.add(result);
                    continue;
                }
                
                // JSON parsing
                Map<String, Object> fieldsMap = parseFieldsJson(request.fieldsJson);
                if (fieldsMap == null) {
                    result.message = 'JSON parsing error';
                    result.errorDetails = 'Invalid JSON format in fieldsJson';
                    results.add(result);
                    continue;
                }
                
                // Choose processing method based on record count
                if (request.recordIds.size() > BATCH_THRESHOLD) {
                    result = processWithBatch(request.recordIds, request.objectType, fieldsMap);
                } else {
                    result = updateRecords(request.recordIds, request.objectType, fieldsMap);
                }
                
            } catch (Exception e) {
                result.message = 'An error occurred: ' + e.getMessage();
                result.errorDetails = e.getStackTraceString();
            }
            
            results.add(result);
        }
        
        return results;
    }
    
    /**
     * @description Parsing JSON string with fields
     * @param fieldsJson JSON string
     * @return Map with fields and values
     */
    private static Map<String, Object> parseFieldsJson(String fieldsJson) {
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(fieldsJson);
        } catch (Exception e) {
            System.debug('JSON parsing error: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * @description Updating records
     * @param recordIds List of record IDs
     * @param objectType Object type
     * @param fieldsMap Map with fields and values
     * @return Update result
     */
    private static UpdateResult updateRecords(List<String> recordIds, String objectType, Map<String, Object> fieldsMap) {
        UpdateResult result = new UpdateResult();
        result.success = false;
        result.updatedRecordsCount = 0;
        
        try {
            // Creating list of records to update
            List<SObject> recordsToUpdate = new List<SObject>();
            
            // Getting object type
            Schema.SObjectType objectSchema = Schema.getGlobalDescribe().get(objectType);
            if (objectSchema == null) {
                result.message = 'Unknown object type: ' + objectType;
                return result;
            }
            
            // Creating records for update
            for (String recordId : recordIds) {
                SObject record = objectSchema.newSObject(recordId);
                
                // Setting fields
                for (String fieldName : fieldsMap.keySet()) {
                    try {
                        // Checking field existence
                        Schema.SObjectField field = objectSchema.getDescribe().fields.getMap().get(fieldName);
                        if (field != null) {
                            Object fieldValue = fieldsMap.get(fieldName);
                            record.put(fieldName, fieldValue);
                        } else {
                            System.debug('Field not found: ' + fieldName);
                        }
                    } catch (Exception e) {
                        System.debug('Error setting field ' + fieldName + ': ' + e.getMessage());
                    }
                }
                
                recordsToUpdate.add(record);
            }
            
            // Updating records
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
                result.success = true;
                result.updatedRecordsCount = recordsToUpdate.size();
                result.message = 'Successfully updated ' + result.updatedRecordsCount + ' records';
            } else {
                result.message = 'No records to update';
            }
            
        } catch (DmlException e) {
            result.message = 'DML error: ' + e.getMessage();
            result.errorDetails = 'DML Error: ' + e.getDmlMessage(0);
        } catch (Exception e) {
            result.message = 'General error: ' + e.getMessage();
            result.errorDetails = e.getStackTraceString();
        }
        
        return result;
    }
    
    /**
     * @description Process records using batch processing
     * @param recordIds List of record IDs
     * @param objectType Object type
     * @param fieldsMap Map with fields and values
     * @return Update result
     */
    private static UpdateResult processWithBatch(List<String> recordIds, String objectType, Map<String, Object> fieldsMap) {
        UpdateResult result = new UpdateResult();
        result.success = false;
        result.updatedRecordsCount = 0;
        
        try {
            // Validate object type
            Schema.SObjectType objectSchema = Schema.getGlobalDescribe().get(objectType);
            if (objectSchema == null) {
                result.message = 'Unknown object type: ' + objectType;
                return result;
            }
            
            // Start batch processing
            Id batchJobId = ObjectUpdateBatch.startBatch(objectType, fieldsMap, recordIds, 200);
            
            result.success = true;
            result.updatedRecordsCount = recordIds.size();
            result.message = 'Batch job started successfully. Job ID: ' + batchJobId + 
                           '. Processing ' + recordIds.size() + ' records asynchronously.';
            
        } catch (Exception e) {
            result.message = 'Error starting batch job: ' + e.getMessage();
            result.errorDetails = e.getStackTraceString();
        }
        
        return result;
    }
}