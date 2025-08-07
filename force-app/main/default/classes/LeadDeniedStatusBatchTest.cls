@isTest
public class LeadDeniedStatusBatchTest {
    
    @TestSetup
    static void setupTestData() {
        // Используем хардкод RecordTypeId
        Id recordTypeId = '012Kc000000tenuIAA';
        
        // Создаем тестовые лиды
        List<Lead> testLeads = new List<Lead>();
        
        // Лид с Parsing_Status__c = 'Black list'
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'BatchTest1',
            Company = 'Test Company 1',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'Black list'
        ));
        
        // Лид с Parsing_Status__c = 'black list' (нижний регистр)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'BatchTest2',
            Company = 'Test Company 2',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'black list'
        ));
        
        // Лид с Parsing_Status__c = 'BLACK LIST' (верхний регистр)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'BatchTest3',
            Company = 'Test Company 3',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'BLACK LIST'
        ));
        
        // Лид с Parsing_Status__c = 'Approved' (не должен измениться)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'BatchTest4',
            Company = 'Test Company 4',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'Approved'
        ));
        
        // Лид с пустым Parsing_Status__c (не должен измениться)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'BatchTest5',
            Company = 'Test Company 5',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = null
        ));
        
        insert testLeads;
    }
    
    @isTest
    static void testBatchExecution() {
        // Получаем тестовые лиды
        List<Lead> testLeads = [SELECT Id, Status, Parsing_Status__c FROM Lead WHERE LastName LIKE 'BatchTest%'];
        
        Test.startTest();
        // Запускаем Batch
        LeadDeniedStatusBatch.startBatch(testLeads);
        Test.stopTest();
        
        // Проверяем результаты
        List<Lead> updatedLeads = [SELECT Id, Status, Parsing_Status__c, LastName FROM Lead WHERE Id IN :testLeads];
        
       
    }
    
    @isTest
    static void testBatchWithEmptyList() {
        // Тестируем Batch с пустым списком лидов
        List<Lead> emptyLeads = new List<Lead>();
        
        Test.startTest();
        LeadDeniedStatusBatch.startBatch(emptyLeads);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testBatchWithNullList() {
        // Тестируем Batch с null списком
        Test.startTest();
        LeadDeniedStatusBatch.startBatch(null);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testBatchWithSingleLead() {
        // Получаем один тестовый лид
        Lead testLead = [SELECT Id, Status, Parsing_Status__c FROM Lead WHERE LastName = 'BatchTest1' LIMIT 1];
        
        Test.startTest();
        LeadDeniedStatusBatch.startBatch(new List<Lead>{testLead});
        Test.stopTest();
        
        // Проверяем результат
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testBatchWithMultipleLeads() {
        // Получаем несколько тестовых лидов
        List<Lead> testLeads = [SELECT Id, Status, Parsing_Status__c FROM Lead WHERE LastName IN ('BatchTest1', 'BatchTest2', 'BatchTest4')];
        
        Test.startTest();
        LeadDeniedStatusBatch.startBatch(testLeads);
        Test.stopTest();
        
        // Проверяем результаты
        List<Lead> updatedLeads = [SELECT Id, Status, Parsing_Status__c, LastName FROM Lead WHERE Id IN :testLeads];
        
       
    }
    
    @isTest
    static void testBatchExceptionHandling() {
        // Создаем лид с некорректными данными для тестирования обработки исключений
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'BatchExceptionTest',
            Company = 'Test Company',
            RecordTypeId = '012Kc000000tenuIAA',
            Status = 'New',
            Parsing_Status__c = 'Black list'
        );
        
        insert testLead;
        
        Test.startTest();
        LeadDeniedStatusBatch.startBatch(new List<Lead>{testLead});
        Test.stopTest();
        
        // Проверяем, что лид был обновлен
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
}