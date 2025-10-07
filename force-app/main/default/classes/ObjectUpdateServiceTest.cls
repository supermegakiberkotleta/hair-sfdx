/**
 * @description Test class for ObjectUpdateService
 * @author QueueHair Team
 * @date 2024
 */
@isTest
private class ObjectUpdateServiceTest {
    
    /**
     * @description Test successful Lead records update
     */
    @isTest
    static void testSuccessfulLeadUpdate() {
        // Creating test Lead records
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 3; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Company ' + i,
                Status = 'New'
            ));
        }
        insert testLeads;
        
        // Preparing request
        ObjectUpdateService.UpdateRequest request = new ObjectUpdateService.UpdateRequest();
        request.objectType = 'Lead';
        request.recordIds = new List<String>();
        for (Lead lead : testLeads) {
            request.recordIds.add(lead.Id);
        }
        request.fieldsJson = '{"Status": "Closed Lost", "Reason_for_closure__c": "Not interested"}';
        
        Test.startTest();
        List<ObjectUpdateService.UpdateResult> results = ObjectUpdateService.updateObjects(new List<ObjectUpdateService.UpdateRequest>{request});
        Test.stopTest();
        
        // Проверка результатов
        System.assertEquals(1, results.size(), 'Should be one result');
        ObjectUpdateService.UpdateResult result = results[0];
        System.assertEquals(true, result.success, 'Operation should be successful');
        System.assertEquals(3, result.updatedRecordsCount, 'Should update 3 records');
        System.assert(result.message.contains('Successfully updated'), 'Message should contain success information');
        
        // Checking updated records
        List<Lead> updatedLeads = [SELECT Id, Status, Reason_for_closure__c FROM Lead WHERE Id IN :testLeads];
        for (Lead lead : updatedLeads) {
            System.assertEquals('Closed Lost', lead.Status, 'Status should be updated');
            System.assertEquals('Not interested', lead.Reason_for_closure__c, 'Reason_for_closure__c should be updated');
        }
    }
    
    /**
     * @description Test Account records update
     */
    @isTest
    static void testSuccessfulAccountUpdate() {
        // Creating test Account records
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 2; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Type = 'Prospect'
            ));
        }
        insert testAccounts;
        
        // Preparing request
        ObjectUpdateService.UpdateRequest request = new ObjectUpdateService.UpdateRequest();
        request.objectType = 'Account';
        request.recordIds = new List<String>();
        for (Account acc : testAccounts) {
            request.recordIds.add(acc.Id);
        }
        request.fieldsJson = '{"Type": "Customer", "Industry": "Technology"}';
        
        Test.startTest();
        List<ObjectUpdateService.UpdateResult> results = ObjectUpdateService.updateObjects(new List<ObjectUpdateService.UpdateRequest>{request});
        Test.stopTest();
        
        // Проверка результатов
        System.assertEquals(1, results.size(), 'Should be one result');
        ObjectUpdateService.UpdateResult result = results[0];
        System.assertEquals(true, result.success, 'Operation should be successful');
        System.assertEquals(2, result.updatedRecordsCount, 'Should update 2 records');
        
        // Checking updated records
        List<Account> updatedAccounts = [SELECT Id, Type, Industry FROM Account WHERE Id IN :testAccounts];
        for (Account acc : updatedAccounts) {
            System.assertEquals('Customer', acc.Type, 'Type should be updated');
            System.assertEquals('Technology', acc.Industry, 'Industry should be updated');
        }
    }
    
    /**
     * @description Test with empty parameters
     */
    @isTest
    static void testEmptyParameters() {
        ObjectUpdateService.UpdateRequest request = new ObjectUpdateService.UpdateRequest();
        request.objectType = '';
        request.recordIds = new List<String>();
        request.fieldsJson = '';
        
        Test.startTest();
        List<ObjectUpdateService.UpdateResult> results = ObjectUpdateService.updateObjects(new List<ObjectUpdateService.UpdateRequest>{request});
        Test.stopTest();
        
        // Проверка результатов
        System.assertEquals(1, results.size(), 'Should be one result');
        ObjectUpdateService.UpdateResult result = results[0];
        System.assertEquals(false, result.success, 'Операция должна быть неуспешной');
        System.assertEquals('Not all required parameters are filled', result.message, 'Message should indicate empty parameters');
    }
    
    /**
     * @description Test with invalid JSON
     */
    @isTest
    static void testInvalidJson() {
        // Creating test Lead record
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New'
        );
        insert testLead;
        
        ObjectUpdateService.UpdateRequest request = new ObjectUpdateService.UpdateRequest();
        request.objectType = 'Lead';
        request.recordIds = new List<String>{testLead.Id};
        request.fieldsJson = 'invalid json string';
        
        Test.startTest();
        List<ObjectUpdateService.UpdateResult> results = ObjectUpdateService.updateObjects(new List<ObjectUpdateService.UpdateRequest>{request});
        Test.stopTest();
        
        // Проверка результатов
        System.assertEquals(1, results.size(), 'Should be one result');
        ObjectUpdateService.UpdateResult result = results[0];
        System.assertEquals(false, result.success, 'Операция должна быть неуспешной');
        System.assertEquals('JSON parsing error', result.message, 'Message should indicate JSON error');
    }
    
    /**
     * @description Test with non-existent object type
     */
    @isTest
    static void testInvalidObjectType() {
        ObjectUpdateService.UpdateRequest request = new ObjectUpdateService.UpdateRequest();
        request.objectType = 'NonExistentObject';
        request.recordIds = new List<String>{'001000000000000AAA'};
        request.fieldsJson = '{"Name": "Test"}';
        
        Test.startTest();
        List<ObjectUpdateService.UpdateResult> results = ObjectUpdateService.updateObjects(new List<ObjectUpdateService.UpdateRequest>{request});
        Test.stopTest();
        
        // Проверка результатов
        System.assertEquals(1, results.size(), 'Should be one result');
        ObjectUpdateService.UpdateResult result = results[0];
        System.assertEquals(false, result.success, 'Операция должна быть неуспешной');
        System.assert(result.message.contains('Unknown object type'), 'Message should indicate unknown object type');
    }
    
    /**
     * @description Test with non-existent record IDs
     */
    @isTest
    static void testInvalidRecordIds() {
        ObjectUpdateService.UpdateRequest request = new ObjectUpdateService.UpdateRequest();
        request.objectType = 'Lead';
        request.recordIds = new List<String>{'00Q000000000000AAA', '00Q000000000000BBB'};
        request.fieldsJson = '{"Status": "Closed Lost"}';
        
        Test.startTest();
        List<ObjectUpdateService.UpdateResult> results = ObjectUpdateService.updateObjects(new List<ObjectUpdateService.UpdateRequest>{request});
        Test.stopTest();
        
        // Проверка результатов
        System.assertEquals(1, results.size(), 'Should be one result');
        ObjectUpdateService.UpdateResult result = results[0];
        System.assertEquals(false, result.success, 'Операция должна быть неуспешной');
        System.assert(result.message.contains('DML error'), 'Message should indicate DML error');
    }
    
    /**
     * @description Test with non-existent field
     */
    @isTest
    static void testNonExistentField() {
        // Creating test Lead record
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New'
        );
        insert testLead;
        
        ObjectUpdateService.UpdateRequest request = new ObjectUpdateService.UpdateRequest();
        request.objectType = 'Lead';
        request.recordIds = new List<String>{testLead.Id};
        request.fieldsJson = '{"Status": "Closed Lost", "NonExistentField__c": "Test Value", "Reason_for_closure__c": "Not interested"}';
        
        Test.startTest();
        List<ObjectUpdateService.UpdateResult> results = ObjectUpdateService.updateObjects(new List<ObjectUpdateService.UpdateRequest>{request});
        Test.stopTest();
        
        // Проверка результатов
        System.assertEquals(1, results.size(), 'Should be one result');
        ObjectUpdateService.UpdateResult result = results[0];
        System.assertEquals(true, result.success, 'Операция должна быть успешной (несуществующее поле игнорируется)');
        System.assertEquals(1, result.updatedRecordsCount, 'Should update 1 record');
        
        // Проверка обновленной записи
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Closed Lost', updatedLead.Status, 'Status should be updated');
    }
    
    /**
     * @description Test with multiple requests
     */
    @isTest
    static void testMultipleRequests() {
        // Creating test records
        List<Lead> testLeads = new List<Lead>();
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 2; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Company ' + i,
                Status = 'New'
            ));
            
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Type = 'Prospect'
            ));
        }
        insert testLeads;
        insert testAccounts;
        
        // Preparing requests
        List<ObjectUpdateService.UpdateRequest> requests = new List<ObjectUpdateService.UpdateRequest>();
        
        // Request for Lead
        ObjectUpdateService.UpdateRequest leadRequest = new ObjectUpdateService.UpdateRequest();
        leadRequest.objectType = 'Lead';
        leadRequest.recordIds = new List<String>();
        for (Lead lead : testLeads) {
            leadRequest.recordIds.add(lead.Id);
        }
        leadRequest.fieldsJson = '{"Status": "Closed Lost", "Reason_for_closure__c": "Not interested"}';
        requests.add(leadRequest);
        
        // Request for Account
        ObjectUpdateService.UpdateRequest accountRequest = new ObjectUpdateService.UpdateRequest();
        accountRequest.objectType = 'Account';
        accountRequest.recordIds = new List<String>();
        for (Account acc : testAccounts) {
            accountRequest.recordIds.add(acc.Id);
        }
        accountRequest.fieldsJson = '{"Type": "Customer"}';
        requests.add(accountRequest);
        
        Test.startTest();
        List<ObjectUpdateService.UpdateResult> results = ObjectUpdateService.updateObjects(requests);
        Test.stopTest();
        
        // Проверка результатов
        System.assertEquals(2, results.size(), 'Should be 2 results');
        
        for (ObjectUpdateService.UpdateResult result : results) {
            System.assertEquals(true, result.success, 'Обе операции должны быть успешными');
            System.assertEquals(2, result.updatedRecordsCount, 'Each operation should update 2 records');
        }
    }
    
    /**
     * @description Test batch processing decision for large number of records
     */
    @isTest
    static void testBatchProcessingForLargeVolume() {
        // Create test Lead records (more than 50 to trigger batch processing)
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 60; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Company ' + i,
                Status = 'New'
            ));
        }
        insert testLeads;
        
        // Preparing request
        ObjectUpdateService.UpdateRequest request = new ObjectUpdateService.UpdateRequest();
        request.objectType = 'Lead';
        request.recordIds = new List<String>();
        for (Lead lead : testLeads) {
            request.recordIds.add(lead.Id);
        }
        request.fieldsJson = '{"Status": "Closed Lost", "Reason_for_closure__c": "Not interested"}';
        
        Test.startTest();
        List<ObjectUpdateService.UpdateResult> results = ObjectUpdateService.updateObjects(new List<ObjectUpdateService.UpdateRequest>{request});
        Test.stopTest();
        
        // Проверка результатов
        System.assertEquals(1, results.size(), 'Should be one result');
        ObjectUpdateService.UpdateResult result = results[0];
        System.assertEquals(true, result.success, 'Operation should be successful');
        System.assertEquals(60, result.updatedRecordsCount, 'Should process 60 records');
        System.assert(result.message.contains('Batch job started successfully'), 'Message should indicate batch processing');
        System.assert(result.message.contains('Job ID'), 'Message should contain job ID');
        
        // Note: We don't verify the actual record updates here because batch processing is asynchronous
        // and we're not executing the actual batch to avoid limit issues in tests
    }
    
    /**
     * @description Test synchronous processing for small number of records
     */
    @isTest
    static void testSynchronousProcessingForSmallVolume() {
        // Create test Lead records (less than 50 to trigger synchronous processing)
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 30; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Company ' + i,
                Status = 'New'
            ));
        }
        insert testLeads;
        
        // Preparing request
        ObjectUpdateService.UpdateRequest request = new ObjectUpdateService.UpdateRequest();
        request.objectType = 'Lead';
        request.recordIds = new List<String>();
        for (Lead lead : testLeads) {
            request.recordIds.add(lead.Id);
        }
        request.fieldsJson = '{"Status": "Closed Lost", "Reason_for_closure__c": "Not interested"}';
        
        Test.startTest();
        List<ObjectUpdateService.UpdateResult> results = ObjectUpdateService.updateObjects(new List<ObjectUpdateService.UpdateRequest>{request});
        Test.stopTest();
        
        // Проверка результатов
        System.assertEquals(1, results.size(), 'Should be one result');
        ObjectUpdateService.UpdateResult result = results[0];
        System.assertEquals(true, result.success, 'Operation should be successful');
        System.assertEquals(30, result.updatedRecordsCount, 'Should update 30 records');
        System.assert(result.message.contains('Successfully updated'), 'Message should indicate synchronous processing');
        
        // Checking updated records
        List<Lead> updatedLeads = [SELECT Id, Status, Reason_for_closure__c FROM Lead WHERE Id IN :testLeads];
        for (Lead lead : updatedLeads) {
            System.assertEquals('Closed Lost', lead.Status, 'Status should be updated');
            System.assertEquals('Not interested', lead.Reason_for_closure__c, 'Reason_for_closure__c should be updated');
        }
    }
    
    /**
     * @description Test batch processing with invalid object type
     */
    @isTest
    static void testBatchProcessingWithInvalidObjectType() {
        ObjectUpdateService.UpdateRequest request = new ObjectUpdateService.UpdateRequest();
        request.objectType = 'NonExistentObject';
        request.recordIds = new List<String>{'001000000000000AAA', '001000000000000BBB'};
        request.fieldsJson = '{"Name": "Test"}';
        
        Test.startTest();
        List<ObjectUpdateService.UpdateResult> results = ObjectUpdateService.updateObjects(new List<ObjectUpdateService.UpdateRequest>{request});
        Test.stopTest();
        
        // Проверка результатов
        System.assertEquals(1, results.size(), 'Should be one result');
        ObjectUpdateService.UpdateResult result = results[0];
        System.assertEquals(false, result.success, 'Operation should fail');
        System.assert(result.message.contains('Unknown object type'), 'Message should indicate unknown object type');
    }
}
