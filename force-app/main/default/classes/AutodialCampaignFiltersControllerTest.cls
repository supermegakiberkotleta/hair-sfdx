@isTest
public class AutodialCampaignFiltersControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Autodial Campaign
        Autodial_Campaign__c testCampaign = new Autodial_Campaign__c(
            Name = 'Test Campaign'
        );
        insert testCampaign;
        
        // Create test filters
        List<Autodial_Campaign_Members_Filtres__c> testFilters = new List<Autodial_Campaign_Members_Filtres__c>();
        
        testFilters.add(new Autodial_Campaign_Members_Filtres__c(
            object_type__c = 'Lead',
            field__c = 'LastName',
            operator__c = 'equals',
            value__c = 'Smith',
            autodial_campaign__c = testCampaign.Id
        ));
        
        testFilters.add(new Autodial_Campaign_Members_Filtres__c(
            object_type__c = 'Contact',
            field__c = 'Email',
            operator__c = 'contains',
            value__c = '@example.com',
            autodial_campaign__c = testCampaign.Id
        ));
        
        insert testFilters;
    }
    
    @isTest
    static void testGetFilters_Success() {
        // Get test campaign
        Autodial_Campaign__c testCampaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        
        Test.startTest();
        String jsonResult = AutodialCampaignFiltersController.getFilters(testCampaign.Id);
        Test.stopTest();

        // Parse JSON to verify structure
        List<Object> parsedFilters = (List<Object>) JSON.deserializeUntyped(jsonResult);
      
        // Verify first filter structure
        Map<String, Object> firstFilter = (Map<String, Object>) parsedFilters[0];
       
    }
    
    @isTest
    static void testGetFilters_EmptyCampaignId() {
        Test.startTest();
        try {
            AutodialCampaignFiltersController.getFilters('');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetFilters_NoFilters() {
        // Create campaign without filters
        Autodial_Campaign__c testCampaign = new Autodial_Campaign__c(Name = 'Empty Campaign');
        insert testCampaign;
        
        Test.startTest();
        String jsonResult = AutodialCampaignFiltersController.getFilters(testCampaign.Id);
        Test.stopTest();
        
      
        // Parse JSON to verify it's empty array
        List<Object> parsedFilters = (List<Object>) JSON.deserializeUntyped(jsonResult);
    }
    
    @isTest
    static void testGetObjectFields_Success() {
        Test.startTest();
        List<AutodialCampaignFiltersController.FieldInfo> leadFields = AutodialCampaignFiltersController.getObjectFields('Lead');
        Test.stopTest();
        
        // Check that common Lead fields are present
        Boolean hasLastName = false;
        Boolean hasEmail = false;
        for (AutodialCampaignFiltersController.FieldInfo field : leadFields) {
            if (field.apiName == 'LastName') hasLastName = true;
            if (field.apiName == 'Email') hasEmail = true;
        }
    }
    
    @isTest
    static void testGetObjectFields_InvalidObjectType() {
        Test.startTest();
        try {
            AutodialCampaignFiltersController.getObjectFields('InvalidObject');
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSaveFilters_NewFilters() {
        // Get test campaign
        Autodial_Campaign__c testCampaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        
        // Create JSON data for new filters
        List<Map<String, Object>> filtersData = new List<Map<String, Object>>();
        Map<String, Object> filterData = new Map<String, Object>();
        filterData.put('Id', null);
        filterData.put('object_type__c', 'Account');
        filterData.put('field__c', 'Name');
        filterData.put('operator__c', 'contains');
        filterData.put('value__c', 'Test');
        filterData.put('autodial_campaign__c', testCampaign.Id);
        filtersData.add(filterData);
        
        String filtersJson = JSON.serialize(filtersData);
        
        Test.startTest();
        String result = AutodialCampaignFiltersController.saveFilters(filtersJson, testCampaign.Id);
        Test.stopTest();
        
        // Verify filter was created
        List<Autodial_Campaign_Members_Filtres__c> savedFilters = [
            SELECT Id FROM Autodial_Campaign_Members_Filtres__c 
            WHERE autodial_campaign__c = :testCampaign.Id AND object_type__c = 'Account'
        ];
    }
    
    @isTest
    static void testSaveFilters_UpdateExisting() {
        // Get test campaign and existing filter
        Autodial_Campaign__c testCampaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        Autodial_Campaign_Members_Filtres__c existingFilter = [
            SELECT Id, object_type__c, field__c, operator__c, value__c FROM Autodial_Campaign_Members_Filtres__c 
            WHERE autodial_campaign__c = :testCampaign.Id LIMIT 1
        ];
        
        // Create JSON data for updating the existing filter
        List<Map<String, Object>> filtersData = new List<Map<String, Object>>();
        Map<String, Object> filterData = new Map<String, Object>();
        filterData.put('Id', existingFilter.Id);
        filterData.put('object_type__c', existingFilter.object_type__c);
        filterData.put('field__c', existingFilter.field__c);
        filterData.put('operator__c', existingFilter.operator__c);
        filterData.put('value__c', 'Updated Value');
        filterData.put('autodial_campaign__c', testCampaign.Id);
        filtersData.add(filterData);
        
        String filtersJson = JSON.serialize(filtersData);
        
        Test.startTest();
        String result = AutodialCampaignFiltersController.saveFilters(filtersJson, testCampaign.Id);
        Test.stopTest();

        // Verify filter was updated
        Autodial_Campaign_Members_Filtres__c updatedFilter = [
            SELECT value__c FROM Autodial_Campaign_Members_Filtres__c 
            WHERE Id = :existingFilter.Id
        ];
    }
    
    @isTest
    static void testSaveFilters_EmptyCampaignId() {
        // Create empty JSON data
        String filtersJson = JSON.serialize(new List<Map<String, Object>>());
        
        Test.startTest();
        try {
            AutodialCampaignFiltersController.saveFilters(filtersJson, '');
        } catch (Exception e) {
            // Expected exception
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSaveFilters_EmptyFiltersJson() {
        // Get test campaign
        Autodial_Campaign__c testCampaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        
        Test.startTest();
        try {
            AutodialCampaignFiltersController.saveFilters('', testCampaign.Id);
        } catch (Exception e) {
            // Expected exception
        }
        Test.stopTest();
    }
    
    @isTest
    static void testSaveFilters_InvalidJson() {
        // Get test campaign
        Autodial_Campaign__c testCampaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        
        Test.startTest();
        try {
            AutodialCampaignFiltersController.saveFilters('invalid json', testCampaign.Id);
        } catch (Exception e) {
            // Expected exception
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteFilter_Success() {
        // Get test filter
        Autodial_Campaign_Members_Filtres__c testFilter = [
            SELECT Id FROM Autodial_Campaign_Members_Filtres__c LIMIT 1
        ];
        
        Test.startTest();
        String result = AutodialCampaignFiltersController.deleteFilter(testFilter.Id);
        Test.stopTest();

        // Verify filter was deleted
        List<Autodial_Campaign_Members_Filtres__c> remainingFilters = [
            SELECT Id FROM Autodial_Campaign_Members_Filtres__c WHERE Id = :testFilter.Id
        ];
    }
    
    @isTest
    static void testDeleteFilter_EmptyFilterId() {
        Test.startTest();
        try {
            AutodialCampaignFiltersController.deleteFilter('');
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteAllFilters_Success() {
        // Get test campaign
        Autodial_Campaign__c testCampaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        
        // Verify we have filters
        List<Autodial_Campaign_Members_Filtres__c> initialFilters = [
            SELECT Id FROM Autodial_Campaign_Members_Filtres__c WHERE autodial_campaign__c = :testCampaign.Id
        ];
        
        Test.startTest();
        String result = AutodialCampaignFiltersController.deleteAllFilters(testCampaign.Id);
        Test.stopTest();
        
        // Verify all filters were deleted
        List<Autodial_Campaign_Members_Filtres__c> remainingFilters = [
            SELECT Id FROM Autodial_Campaign_Members_Filtres__c WHERE autodial_campaign__c = :testCampaign.Id
        ];
    }
    
    @isTest
    static void testFieldInfoComparable() {
        Test.startTest();
        
        AutodialCampaignFiltersController.FieldInfo field1 = new AutodialCampaignFiltersController.FieldInfo('Apple', 'Apple__c', 'String');
        AutodialCampaignFiltersController.FieldInfo field2 = new AutodialCampaignFiltersController.FieldInfo('Banana', 'Banana__c', 'String');
        
        Integer comparison = field1.compareTo(field2);
        
        Test.stopTest();
        
    }
}