/**
 * @description Batch class for updating large volumes of objects
 * @author QueueHair Team
 * @date 2024
 */
public class ObjectUpdateBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    private String objectType;
    private Map<String, Object> fieldsMap;
    private List<String> recordIds;
    private String batchId;
    
    // Results tracking
    public Integer totalProcessed = 0;
    public Integer totalSuccess = 0;
    public Integer totalErrors = 0;
    public List<String> errorMessages = new List<String>();
    
    /**
     * @description Constructor
     * @param objectType Object type to update
     * @param fieldsMap Map of fields and values to update
     * @param recordIds List of record IDs to update
     * @param batchId Unique batch identifier
     */
    public ObjectUpdateBatch(String objectType, Map<String, Object> fieldsMap, List<String> recordIds, String batchId) {
        this.objectType = objectType;
        this.fieldsMap = fieldsMap;
        this.recordIds = recordIds;
        this.batchId = batchId;
    }
    
    /**
     * @description Start method - returns query locator for records to process
     * @param bc Batchable context
     * @return QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Create dynamic SOQL query
        String query = 'SELECT Id FROM ' + objectType + ' WHERE Id IN :recordIds';
        return Database.getQueryLocator(query);
    }
    
    /**
     * @description Execute method - processes batch of records
     * @param bc Batchable context
     * @param scope List of records to process
     */
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<SObject> recordsToUpdate = new List<SObject>();
        
        try {
            // Get object schema
            Schema.SObjectType objectSchema = Schema.getGlobalDescribe().get(objectType);
            if (objectSchema == null) {
                errorMessages.add('Unknown object type: ' + objectType);
                return;
            }
            
            // Prepare records for update
            for (SObject record : scope) {
                SObject recordToUpdate = objectSchema.newSObject(record.Id);
                
                // Set fields
                for (String fieldName : fieldsMap.keySet()) {
                    try {
                        Schema.SObjectField field = objectSchema.getDescribe().fields.getMap().get(fieldName);
                        if (field != null) {
                            Object fieldValue = fieldsMap.get(fieldName);
                            recordToUpdate.put(fieldName, fieldValue);
                        }
                    } catch (Exception e) {
                        System.debug('Error setting field ' + fieldName + ': ' + e.getMessage());
                    }
                }
                
                recordsToUpdate.add(recordToUpdate);
            }
            
            // Update records
            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
                totalSuccess += recordsToUpdate.size();
            }
            
        } catch (DmlException e) {
            totalErrors += scope.size();
            errorMessages.add('DML Error in batch: ' + e.getMessage());
            System.debug('DML Error: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            totalErrors += scope.size();
            errorMessages.add('General Error in batch: ' + e.getMessage());
            System.debug('General Error: ' + e.getStackTraceString());
        }
        
        totalProcessed += scope.size();
    }
    
    /**
     * @description Finish method - called when batch completes
     * @param bc Batchable context
     */
    public void finish(Database.BatchableContext bc) {
        // Log completion
        System.debug('Batch completed. Processed: ' + totalProcessed + 
                    ', Success: ' + totalSuccess + 
                    ', Errors: ' + totalErrors);
        
        // You can add additional logic here like:
        // - Sending notifications
        // - Creating log records
        // - Updating status fields
    }
    
    /**
     * @description Static method to start batch processing
     * @param objectType Object type to update
     * @param fieldsMap Map of fields and values to update
     * @param recordIds List of record IDs to update
     * @param batchSize Batch size (optional, defaults to 200)
     * @return Id of the batch job
     */
    public static Id startBatch(String objectType, Map<String, Object> fieldsMap, List<String> recordIds, Integer batchSize) {
        String batchId = 'ObjectUpdate_' + objectType + '_' + System.currentTimeMillis();
        ObjectUpdateBatch batch = new ObjectUpdateBatch(objectType, fieldsMap, recordIds, batchId);
        
        if (batchSize == null || batchSize <= 0) {
            batchSize = 200; // Default batch size
        }
        
        return Database.executeBatch(batch, batchSize);
    }
}
