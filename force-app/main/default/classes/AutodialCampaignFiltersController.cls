public with sharing class AutodialCampaignFiltersController {
    
    /**
     * Get all filters for a specific Autodial Campaign as JSON string
     */
    @AuraEnabled(cacheable=false)
    public static String getFilters(String campaignId) {
        if (String.isBlank(campaignId)) {
            throw new AuraHandledException('Campaign ID is required');
        }
        
        try {
            List<Autodial_Campaign_Members_Filtres__c> filters = [
                SELECT Id, object_type__c, field__c, operator__c, value__c, autodial_campaign__c
                FROM Autodial_Campaign_Members_Filtres__c
                WHERE autodial_campaign__c = :campaignId
                ORDER BY CreatedDate
            ];
            
            System.debug('=== getFilters method ===');
            System.debug('Campaign ID: ' + campaignId);
            System.debug('Found ' + filters.size() + ' filters');
            
            // Convert to simple map structure for JSON serialization
            List<Map<String, Object>> filtersForJson = new List<Map<String, Object>>();
            
            for (Integer i = 0; i < filters.size(); i++) {
                Autodial_Campaign_Members_Filtres__c filter = filters[i];
                
                Map<String, Object> filterMap = new Map<String, Object>{
                    'Id' => filter.Id,
                    'object_type__c' => filter.object_type__c,
                    'field__c' => filter.field__c,
                    'operator__c' => filter.operator__c,
                    'value__c' => filter.value__c,
                    'autodial_campaign__c' => filter.autodial_campaign__c
                };
                
                filtersForJson.add(filterMap);
                System.debug('Filter ' + i + ': ' + JSON.serialize(filterMap));
            }
            
            String jsonResult = JSON.serialize(filtersForJson);
            System.debug('Final JSON result: ' + jsonResult);
            
            return jsonResult;
        } catch (Exception e) {
            System.debug('Exception in getFilters: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving filters: ' + e.getMessage());
        }
    }
    
    /**
     * Get available fields for a specific object type
     */
    @AuraEnabled(cacheable=false)
    public static List<FieldInfo> getObjectFields(String objectType) {
        System.debug('=== getObjectFields called ===');
        System.debug('objectType: ' + objectType);
        
        if (String.isBlank(objectType)) {
            System.debug('Object type is blank, returning empty list');
            return new List<FieldInfo>();
        }
        
        try {
            List<FieldInfo> fieldList = new List<FieldInfo>();
            
            // Get object describe
            Schema.SObjectType objectSchema = Schema.getGlobalDescribe().get(objectType);
            System.debug('objectSchema: ' + objectSchema);
            
            if (objectSchema == null) {
                System.debug('Object schema is null for type: ' + objectType);
                throw new AuraHandledException('Invalid object type: ' + objectType);
            }
            
            Map<String, Schema.SObjectField> fieldMap = objectSchema.getDescribe().fields.getMap();
            System.debug('Total fields found: ' + fieldMap.size());
            
            // Filter fields based on type and accessibility
            Integer accessibleCount = 0;
            Integer filterableCount = 0;
            
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                
                System.debug('Checking field: ' + fieldName + 
                           ', isAccessible: ' + fieldDescribe.isAccessible() + 
                           ', isCalculated: ' + fieldDescribe.isCalculated() + 
                           ', isFilterable: ' + isFilterableField(fieldDescribe));
                
                // Only include accessible, non-system fields
                if (fieldDescribe.isAccessible()) {
                    accessibleCount++;
                    
                    if (!fieldDescribe.isCalculated() && isFilterableField(fieldDescribe)) {
                        filterableCount++;
                        
                        fieldList.add(new FieldInfo(
                            fieldDescribe.getLabel(),
                            fieldDescribe.getName(),
                            fieldDescribe.getType().name()
                        ));
                        
                        System.debug('Added field: ' + fieldDescribe.getName() + ' (' + fieldDescribe.getLabel() + ')');
                    }
                }
            }
            
            System.debug('Accessible fields: ' + accessibleCount);
            System.debug('Filterable fields: ' + filterableCount);
            System.debug('Final fieldList size: ' + fieldList.size());
            
            // Sort by label
            fieldList.sort();
            return fieldList;
            
        } catch (Exception e) {
            System.debug('Exception in getObjectFields: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error retrieving fields: ' + e.getMessage());
        }
    }
    
    /**
     * Save filters using JSON data
     */
    @AuraEnabled
    public static String saveFilters(String filtersJson, String campaignId) {
        System.debug('=== saveFilters called ===');
        System.debug('campaignId: ' + campaignId);
        System.debug('filtersJson: ' + filtersJson);
        
        if (String.isBlank(campaignId)) {
            throw new AuraHandledException('Campaign ID is required');
        }
        
        if (String.isBlank(filtersJson)) {
            throw new AuraHandledException('Filters data is required');
        }
        
        try {
            // Parse JSON data
            List<Object> filtersData = (List<Object>) JSON.deserializeUntyped(filtersJson);
            System.debug('Parsed filtersData size: ' + filtersData.size());
            
            List<Autodial_Campaign_Members_Filtres__c> filtersToUpsert = new List<Autodial_Campaign_Members_Filtres__c>();
            
            for (Integer i = 0; i < filtersData.size(); i++) {
                Map<String, Object> filterData = (Map<String, Object>) filtersData[i];
                System.debug('Processing filter ' + i + ': ' + filterData);
                
                // Validate required fields
                String objectType = (String) filterData.get('object_type__c');
                String field = (String) filterData.get('field__c');
                String operator = (String) filterData.get('operator__c');
                String value = (String) filterData.get('value__c');
                
                if (String.isBlank(objectType) || String.isBlank(field) || 
                    String.isBlank(operator) || String.isBlank(value)) {
                    System.debug('Skipping filter ' + i + ' due to missing required fields');
                    continue;
                }
                
                Autodial_Campaign_Members_Filtres__c filter = new Autodial_Campaign_Members_Filtres__c();
                
                // Set fields from JSON data
                if (filterData.containsKey('Id') && filterData.get('Id') != null) {
                    filter.Id = (String) filterData.get('Id');
                }
                
                filter.Object_type__c = objectType;
                filter.Field__c = field;
                filter.Operator__c = operator;
                filter.Value__c = value;
                filter.Autodial_Campaign__c = campaignId; // Use the campaignId parameter
                
                System.debug('Created filter: ' + filter);
                filtersToUpsert.add(filter);
            }
            
            System.debug('Total filters to upsert: ' + filtersToUpsert.size());
            
            if (!filtersToUpsert.isEmpty()) {
                System.debug('About to upsert filters...');
                
                try {
                    upsert filtersToUpsert;
                    System.debug('Upsert successful');
                } catch (DmlException dmlEx) {
                    System.debug('DML Exception: ' + dmlEx.getMessage());
                    System.debug('DML Exception details: ' + dmlEx.getDmlMessage(0));
                    throw new AuraHandledException('Database error: ' + dmlEx.getDmlMessage(0));
                }
            }
            
            return 'Filters saved successfully';
            
        } catch (Exception e) {
            System.debug('Exception in saveFilters: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error saving filters: ' + e.getMessage());
        }
    }
    
    /**
     * Delete a specific filter
     */
    @AuraEnabled
    public static String deleteFilter(String filterId) {
        System.debug('=== deleteFilter called ===');
        System.debug('filterId: ' + filterId);
        
        if (String.isBlank(filterId)) {
            System.debug('Filter ID is blank, throwing exception');
            throw new AuraHandledException('Filter ID is required');
        }
        
        try {
            // First check if the filter exists
            List<Autodial_Campaign_Members_Filtres__c> filtersToDelete = [
                SELECT Id, object_type__c, field__c, operator__c, value__c, autodial_campaign__c
                FROM Autodial_Campaign_Members_Filtres__c 
                WHERE Id = :filterId 
                LIMIT 1
            ];
            
            System.debug('Found ' + filtersToDelete.size() + ' filters to delete');
            
            if (filtersToDelete.isEmpty()) {
                System.debug('No filter found with ID: ' + filterId);
                throw new AuraHandledException('Filter not found with ID: ' + filterId);
            }
            
            Autodial_Campaign_Members_Filtres__c filterToDelete = filtersToDelete[0];
            System.debug('Deleting filter: ' + filterToDelete);
            
            delete filterToDelete;
            System.debug('Filter deleted successfully');
            
            return 'Filter deleted successfully';
            
        } catch (DmlException dmlEx) {
            System.debug('DML Exception in deleteFilter: ' + dmlEx.getMessage());
            System.debug('DML Exception details: ' + dmlEx.getDmlMessage(0));
            throw new AuraHandledException('Database error deleting filter: ' + dmlEx.getDmlMessage(0));
        } catch (Exception e) {
            System.debug('Exception in deleteFilter: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error deleting filter: ' + e.getMessage());
        }
    }
    
    /**
     * Delete all filters for a campaign
     */
    @AuraEnabled
    public static String deleteAllFilters(String campaignId) {
        System.debug('=== deleteAllFilters called ===');
        System.debug('campaignId: ' + campaignId);
        
        if (String.isBlank(campaignId)) {
            System.debug('Campaign ID is blank, throwing exception');
            throw new AuraHandledException('Campaign ID is required');
        }
        
        try {
            List<Autodial_Campaign_Members_Filtres__c> filtersToDelete = [
                SELECT Id, object_type__c, field__c, operator__c, value__c, autodial_campaign__c
                FROM Autodial_Campaign_Members_Filtres__c 
                WHERE autodial_campaign__c = :campaignId
            ];
            
            System.debug('Found ' + filtersToDelete.size() + ' filters to delete for campaign: ' + campaignId);
            
            if (!filtersToDelete.isEmpty()) {
                System.debug('Deleting ' + filtersToDelete.size() + ' filters');
                delete filtersToDelete;
                System.debug('All filters deleted successfully');
            } else {
                System.debug('No filters found to delete');
            }
            
            return 'All filters deleted successfully';
            
        } catch (DmlException dmlEx) {
            System.debug('DML Exception in deleteAllFilters: ' + dmlEx.getMessage());
            System.debug('DML Exception details: ' + dmlEx.getDmlMessage(0));
            throw new AuraHandledException('Database error deleting filters: ' + dmlEx.getDmlMessage(0));
        } catch (Exception e) {
            System.debug('Exception in deleteAllFilters: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error deleting filters: ' + e.getMessage());
        }
    }
    
    /**
     * Check if field is suitable for filtering
     */
    private static Boolean isFilterableField(Schema.DescribeFieldResult fieldDescribe) {
        String fieldName = fieldDescribe.getName();
        
        // Exclude system fields
        if (fieldName.endsWith('__c') == false && 
            !fieldName.equalsIgnoreCase('Name') &&
            !fieldName.equalsIgnoreCase('Email') &&
            !fieldName.equalsIgnoreCase('Phone') &&
            !fieldName.equalsIgnoreCase('LastName') &&
            !fieldName.equalsIgnoreCase('FirstName') &&
            !fieldName.equalsIgnoreCase('Company') &&
            !fieldName.equalsIgnoreCase('Title') &&
            !fieldName.equalsIgnoreCase('Industry') &&
            !fieldName.equalsIgnoreCase('Rating') &&
            !fieldName.equalsIgnoreCase('LeadSource') &&
            !fieldName.equalsIgnoreCase('Status') &&
            !fieldName.equalsIgnoreCase('Description') &&
            !fieldName.equalsIgnoreCase('Website') &&
            !fieldName.equalsIgnoreCase('AnnualRevenue') &&
            !fieldName.equalsIgnoreCase('NumberOfEmployees') &&
            !fieldName.equalsIgnoreCase('Type') &&
            !fieldName.equalsIgnoreCase('AccountSource') &&
            !fieldName.equalsIgnoreCase('IsConverted') &&
            !fieldName.equalsIgnoreCase('ConvertedAccountId') &&
            !fieldName.equalsIgnoreCase('ConvertedContactId') &&
            !fieldName.equalsIgnoreCase('ConvertedOpportunityId') &&
            !fieldName.equalsIgnoreCase('CreatedDate') &&
            !fieldName.equalsIgnoreCase('LastModifiedDate')) {
            return false;
        }
        
        Schema.DisplayType fieldType = fieldDescribe.getType();
        
        // Include common filterable field types
        return fieldType == Schema.DisplayType.STRING ||
               fieldType == Schema.DisplayType.EMAIL ||
               fieldType == Schema.DisplayType.PHONE ||
               fieldType == Schema.DisplayType.PICKLIST ||
               fieldType == Schema.DisplayType.MULTIPICKLIST ||
               fieldType == Schema.DisplayType.CURRENCY ||
               fieldType == Schema.DisplayType.DOUBLE ||
               fieldType == Schema.DisplayType.INTEGER ||
               fieldType == Schema.DisplayType.PERCENT ||
               fieldType == Schema.DisplayType.DATE ||
               fieldType == Schema.DisplayType.DATETIME ||
               fieldType == Schema.DisplayType.BOOLEAN;
    }
    
    /**
     * Wrapper class for field information
     */
    public class FieldInfo implements Comparable {
        @AuraEnabled public String label { get; set; }
        @AuraEnabled public String apiName { get; set; }
        @AuraEnabled public String dataType { get; set; }
        
        public FieldInfo() {
            // Default constructor required for serialization
        }
        
        public FieldInfo(String label, String apiName, String dataType) {
            this.label = label;
            this.apiName = apiName;
            this.dataType = dataType;
        }
        
        public Integer compareTo(Object compareTo) {
            FieldInfo other = (FieldInfo) compareTo;
            return this.label.compareTo(other.label);
        }
    }
}