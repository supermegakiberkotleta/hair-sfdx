@isTest
private class LeadStatusHistoryControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестового лида
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = '012Kc000000tenuIAA' // Loan_Leads
        );
        insert testLead;
        
        // Симулируем изменения статуса для создания истории
        // В тестах мы не можем напрямую создавать LeadHistory, 
        // но можем обновлять статус лида, что автоматически создаст записи в истории
        testLead.Status = 'Qualified';
        update testLead;
        
        testLead.Status = 'Working';
        update testLead;
        
        testLead.Status = 'Call after';
        update testLead;
    }
    
    @isTest
    static void testGetPreviousStatus() {
        // Получаем тестового лида
        Lead testLead = [SELECT Id, Status FROM Lead WHERE LastName = 'Lead' LIMIT 1];
        
        Test.startTest();
        
        // Тестируем получение предыдущего статуса
        String previousStatus = LeadStatusHistoryController.getPreviousStatus(testLead.Id);
        
        Test.stopTest();
      
    }
    
    @isTest
    static void testGetPreviousStatusWithNoHistory() {
        // Создаем нового лида без истории изменений
        Lead newLead = new Lead(
            FirstName = 'New',
            LastName = 'Lead',
            Company = 'New Company',
            Status = 'Call after',
            RecordTypeId = '012Kc000000tenuIAA'
        );
        insert newLead;
        
        Test.startTest();
        
        // Тестируем получение предыдущего статуса для лида без истории
        String previousStatus = LeadStatusHistoryController.getPreviousStatus(newLead.Id);
        
        Test.stopTest();
        
    }
    
    @isTest
    static void testGetStatusHistory() {
        // Получаем тестового лида
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Lead' LIMIT 1];
        
        Test.startTest();
        
        // Тестируем получение полной истории статусов
        List<String> statusHistory = LeadStatusHistoryController.getStatusHistory(testLead.Id);
        
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testGetStatusHistoryWithNoHistory() {
        // Создаем нового лида без истории
        Lead newLead = new Lead(
            FirstName = 'New',
            LastName = 'Lead',
            Company = 'New Company',
            Status = 'New',
            RecordTypeId = '012Kc000000tenuIAA'
        );
        insert newLead;
        
        Test.startTest();
        
        // Тестируем получение истории для лида без истории
        List<String> statusHistory = LeadStatusHistoryController.getStatusHistory(newLead.Id);
        
        Test.stopTest();
        
     
    }
    
    @isTest
    static void testGetDetailedStatusHistory() {
        // Получаем тестового лида
        Lead testLead = [SELECT Id FROM Lead WHERE LastName = 'Lead' LIMIT 1];
        
        Test.startTest();
        
        // Тестируем получение детальной истории
        List<Map<String, Object>> detailedHistory = LeadStatusHistoryController.getDetailedStatusHistory(testLead.Id);
        
        Test.stopTest();
        
     
    }
    
    @isTest
    static void testGetPreviousStatusWithInvalidId() {
        Test.startTest();
        
        // Тестируем с неверным ID
        String previousStatus = LeadStatusHistoryController.getPreviousStatus('001000000000000');
        
        Test.stopTest();
        
      
    }
}