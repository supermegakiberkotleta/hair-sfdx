@isTest
private class CheckScanDataControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестовый Lead
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Company = 'Test Company',
            Email = 'test@example.com'
        );
        insert testLead;
    }
    
    @isTest
    static void testGetScanDataByLeadId_NoData() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        Scan_Data__c result = CheckScanDataController.getScanDataByLeadId(testLead.Id);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null when no scan data exists');
    }
    
    @isTest
    static void testSaveScanData() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String testBase64 = 'dGVzdA=='; // base64 для "test"
        String fileName = 'test.jpg';
        String routingNumber = '072403004';
        String accountNumber = '9950106444';
        String companyName = 'Test Company Inc';
        String address = '123 Test Street, Test City, TS 12345';
        
        Test.startTest();
        Scan_Data__c result = CheckScanDataController.saveScanData(testLead.Id, fileName, testBase64, routingNumber, accountNumber, companyName, address);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return created scan data record');
        System.assertEquals(testLead.Id, result.Lead__c, 'Lead should match');
        System.assertNotEquals(null, result.File_Id__c, 'File Id should be set');
        System.assertEquals(routingNumber, result.Routing_Number__c, 'Routing number should match');
        System.assertEquals(accountNumber, result.Account_Number__c, 'Account number should match');
        System.assertEquals(companyName, result.Company_name__c, 'Company name should match');
        System.assertEquals(address, result.Address__c, 'Address should match');
        System.assertNotEquals(null, result.Scan_Date__c, 'Scan date should be set');
        System.assertEquals('check', result.Type__c, 'Type should be set to check');
    }
    
    @isTest
    static void testSaveScanData_UpdateExisting() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String testBase64 = 'dGVzdA=='; // base64 для "test"
        String fileName = 'test.jpg';
        String routingNumber = '072403004';
        String accountNumber = '9950106444';
        String companyName = 'Test Company Inc';
        String address = '123 Test Street, Test City, TS 12345';
        
        // Создаем первую запись
        CheckScanDataController.saveScanData(testLead.Id, fileName, testBase64, routingNumber, accountNumber, companyName, address);
        
        // Создаем вторую запись (должна заменить первую)
        String newBase64 = 'bmV3'; // base64 для "new"
        String newFileName = 'new.jpg';
        String newRoutingNumber = '123456789';
        String newAccountNumber = '987654321';
        String newCompanyName = 'New Company LLC';
        String newAddress = '456 New Avenue, New City, NC 54321';
        
        Test.startTest();
        Scan_Data__c result = CheckScanDataController.saveScanData(testLead.Id, newFileName, newBase64, newRoutingNumber, newAccountNumber, newCompanyName, newAddress);
        Test.stopTest();
        
        // Проверяем, что осталась только одна запись с типом 'check'
        List<Scan_Data__c> allRecords = [SELECT Id FROM Scan_Data__c WHERE Lead__c = :testLead.Id AND Type__c = 'check'];
        System.assertEquals(1, allRecords.size(), 'Should have only one record with type check');
        
        System.assertNotEquals(null, result.File_Id__c, 'Should have new file id');
        System.assertEquals(newRoutingNumber, result.Routing_Number__c, 'Should have new routing number');
        System.assertEquals(newAccountNumber, result.Account_Number__c, 'Should have new account number');
        System.assertEquals(newCompanyName, result.Company_name__c, 'Should have new company name');
        System.assertEquals(newAddress, result.Address__c, 'Should have new address');
    }
    
    @isTest
    static void testGetScanDataByLeadId_WithData() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String testBase64 = 'dGVzdA=='; // base64 для "test"
        String fileName = 'test.jpg';
        String routingNumber = '072403004';
        String accountNumber = '9950106444';
        String companyName = 'Test Company Inc';
        String address = '123 Test Street, Test City, TS 12345';
        
        // Создаем запись
        CheckScanDataController.saveScanData(testLead.Id, fileName, testBase64, routingNumber, accountNumber, companyName, address);
        
        Test.startTest();
        Scan_Data__c result = CheckScanDataController.getScanDataByLeadId(testLead.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return scan data record');
        System.assertEquals(testLead.Id, result.Lead__c, 'Lead should match');
        System.assertNotEquals(null, result.File_Id__c, 'File Id should be set');
        System.assertEquals(routingNumber, result.Routing_Number__c, 'Routing number should match');
        System.assertEquals(accountNumber, result.Account_Number__c, 'Account number should match');
        System.assertEquals(companyName, result.Company_name__c, 'Company name should match');
        System.assertEquals(address, result.Address__c, 'Address should match');
        System.assertEquals('check', result.Type__c, 'Type should be check');
    }
    
    @isTest
    static void testDeleteScanData() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String testBase64 = 'dGVzdA=='; // base64 для "test"
        String fileName = 'test.jpg';
        String routingNumber = '072403004';
        String accountNumber = '9950106444';
        String companyName = 'Test Company Inc';
        String address = '123 Test Street, Test City, TS 12345';
        
        // Создаем запись
        CheckScanDataController.saveScanData(testLead.Id, fileName, testBase64, routingNumber, accountNumber, companyName, address);
        
        // Проверяем, что запись создана
        List<Scan_Data__c> recordsBefore = [SELECT Id FROM Scan_Data__c WHERE Lead__c = :testLead.Id AND Type__c = 'check'];
        System.assertEquals(1, recordsBefore.size(), 'Should have one record before deletion');
        
        Test.startTest();
        CheckScanDataController.deleteScanData(testLead.Id);
        Test.stopTest();
        
        // Проверяем, что запись удалена
        List<Scan_Data__c> recordsAfter = [SELECT Id FROM Scan_Data__c WHERE Lead__c = :testLead.Id AND Type__c = 'check'];
        System.assertEquals(0, recordsAfter.size(), 'Should have no records after deletion');
    }
    
    @isTest
    static void testDeleteScanData_NoData() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        // Не должно вызывать ошибку
        CheckScanDataController.deleteScanData(testLead.Id);
        Test.stopTest();
        
        // Проверяем, что нет записей
        List<Scan_Data__c> records = [SELECT Id FROM Scan_Data__c WHERE Lead__c = :testLead.Id AND Type__c = 'check'];
        System.assertEquals(0, records.size(), 'Should have no records');
    }
    
    @isTest
    static void testGetFileUrl() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String testBase64 = 'dGVzdA=='; // base64 для "test"
        String fileName = 'test.jpg';
        String routingNumber = '072403004';
        String accountNumber = '9950106444';
        String companyName = 'Test Company Inc';
        String address = '123 Test Street, Test City, TS 12345';
        
        // Создаем запись
        Scan_Data__c scanData = CheckScanDataController.saveScanData(testLead.Id, fileName, testBase64, routingNumber, accountNumber, companyName, address);
        
        Test.startTest();
        String fileUrl = CheckScanDataController.getFileUrl(scanData.File_Id__c);
        Test.stopTest();
        
        System.assertNotEquals(null, fileUrl, 'Should return file URL');
        System.assert(fileUrl.startsWith('/sfc/servlet.shepherd/document/download/'), 'URL should have correct format');
    }
    
    @isTest
    static void testGetFileUrl_InvalidId() {
        Test.startTest();
        String fileUrl = CheckScanDataController.getFileUrl('invalid-id');
        Test.stopTest();
        
        System.assertEquals(null, fileUrl, 'Should return null for invalid file ID');
    }
    
    @isTest
    static void testTypeFieldFiltering() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String testBase64 = 'dGVzdA=='; // base64 для "test"
        String fileName = 'test.jpg';
        String routingNumber = '072403004';
        String accountNumber = '9950106444';
        String companyName = 'Test Company Inc';
        String address = '123 Test Street, Test City, TS 12345';
        
        // Создаем запись с типом 'check'
        CheckScanDataController.saveScanData(testLead.Id, fileName, testBase64, routingNumber, accountNumber, companyName, address);
        
        // Проверяем, что getScanDataByLeadId возвращает только записи с типом 'check'
        Scan_Data__c result = CheckScanDataController.getScanDataByLeadId(testLead.Id);
        System.assertNotEquals(null, result, 'Should return scan data record');
        System.assertEquals('check', result.Type__c, 'Type should be check');
        
        // Проверяем, что общее количество записей (включая другие типы) может быть больше
        List<Scan_Data__c> allRecords = [SELECT Id, Type__c FROM Scan_Data__c WHERE Lead__c = :testLead.Id];
        System.assert(allRecords.size() >= 1, 'Should have at least one record');
        
        // Проверяем, что есть хотя бы одна запись с типом 'check'
        List<Scan_Data__c> checkRecords = [SELECT Id FROM Scan_Data__c WHERE Lead__c = :testLead.Id AND Type__c = 'check'];
        System.assertEquals(1, checkRecords.size(), 'Should have exactly one check record');
    }
}