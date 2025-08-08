@isTest
private class ScanDataControllerTest {
    
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
        Scan_Data__c result = ScanDataController.getScanDataByLeadId(testLead.Id);
        Test.stopTest();
        
        System.assertEquals(null, result, 'Should return null when no scan data exists');
    }
    
    @isTest
    static void testSaveScanData() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String testBase64 = 'dGVzdA=='; // base64 для "test"
        String fileName = 'test.pdf';
        String testName = 'John Doe';
        
        Test.startTest();
        Scan_Data__c result = ScanDataController.saveScanData(testLead.Id, fileName, testBase64, testName);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return created scan data record');
        System.assertEquals(testLead.Id, result.Lead__c, 'Lead should match');
        System.assertNotEquals(null, result.File_Id__c, 'File Id should be set');
        System.assertEquals(testName, result.Name__c, 'Scanned name should match');
        System.assertNotEquals(null, result.Scan_Date__c, 'Scan date should be set');
    }
    
    @isTest
    static void testSaveScanData_UpdateExisting() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String testBase64 = 'dGVzdA=='; // base64 для "test"
        String fileName = 'test.pdf';
        String testName = 'John Doe';
        
        // Создаем первую запись
        ScanDataController.saveScanData(testLead.Id, fileName, testBase64, testName);
        
        // Создаем вторую запись (должна заменить первую)
        String newBase64 = 'bmV3'; // base64 для "new"
        String newFileName = 'new.pdf';
        String newName = 'Jane Doe';
        
        Test.startTest();
        Scan_Data__c result = ScanDataController.saveScanData(testLead.Id, newFileName, newBase64, newName);
        Test.stopTest();
        
        // Проверяем, что осталась только одна запись
        List<Scan_Data__c> allRecords = [SELECT Id FROM Scan_Data__c WHERE Lead__c = :testLead.Id];
        System.assertEquals(1, allRecords.size(), 'Should have only one record');
        
        System.assertNotEquals(null, result.File_Id__c, 'Should have new file id');
        System.assertEquals(newName, result.Name__c, 'Should have new name');
    }
    
    @isTest
    static void testGetScanDataByLeadId_WithData() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String testBase64 = 'dGVzdA=='; // base64 для "test"
        String fileName = 'test.pdf';
        String testName = 'John Doe';
        
        // Создаем запись
        ScanDataController.saveScanData(testLead.Id, fileName, testBase64, testName);
        
        Test.startTest();
        Scan_Data__c result = ScanDataController.getScanDataByLeadId(testLead.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return scan data record');
        System.assertEquals(testLead.Id, result.Lead__c, 'Lead should match');
        System.assertNotEquals(null, result.File_Id__c, 'File Id should be set');
        System.assertEquals(testName, result.Name__c, 'Scanned name should match');
    }
    
    @isTest
    static void testDeleteScanData() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String testBase64 = 'dGVzdA=='; // base64 для "test"
        String fileName = 'test.pdf';
        String testName = 'John Doe';
        
        // Создаем запись
        ScanDataController.saveScanData(testLead.Id, fileName, testBase64, testName);
        
        // Проверяем, что запись создана
        List<Scan_Data__c> recordsBefore = [SELECT Id FROM Scan_Data__c WHERE Lead__c = :testLead.Id];
        System.assertEquals(1, recordsBefore.size(), 'Should have one record before deletion');
        
        Test.startTest();
        ScanDataController.deleteScanData(testLead.Id);
        Test.stopTest();
        
        // Проверяем, что запись удалена
        List<Scan_Data__c> recordsAfter = [SELECT Id FROM Scan_Data__c WHERE Lead__c = :testLead.Id];
        System.assertEquals(0, recordsAfter.size(), 'Should have no records after deletion');
    }
    
    @isTest
    static void testDeleteScanData_NoData() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        
        Test.startTest();
        // Не должно вызывать ошибку
        ScanDataController.deleteScanData(testLead.Id);
        Test.stopTest();
        
        // Проверяем, что нет записей
        List<Scan_Data__c> records = [SELECT Id FROM Scan_Data__c WHERE Lead__c = :testLead.Id];
        System.assertEquals(0, records.size(), 'Should have no records');
    }
    
    @isTest
    static void testGetFileUrl() {
        Lead testLead = [SELECT Id FROM Lead LIMIT 1];
        String testBase64 = 'dGVzdA=='; // base64 для "test"
        String fileName = 'test.pdf';
        String testName = 'John Doe';
        
        // Создаем запись
        Scan_Data__c scanData = ScanDataController.saveScanData(testLead.Id, fileName, testBase64, testName);
        
        Test.startTest();
        String fileUrl = ScanDataController.getFileUrl(scanData.File_Id__c);
        Test.stopTest();
        
        System.assertNotEquals(null, fileUrl, 'Should return file URL');
        System.assert(fileUrl.startsWith('/sfc/servlet.shepherd/document/download/'), 'URL should have correct format');
    }
    
    @isTest
    static void testGetFileUrl_InvalidId() {
        Test.startTest();
        String fileUrl = ScanDataController.getFileUrl('invalid-id');
        Test.stopTest();
        
        System.assertEquals(null, fileUrl, 'Should return null for invalid file ID');
    }
} 