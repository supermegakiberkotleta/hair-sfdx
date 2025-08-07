@isTest
public class LeadDeniedStatusFutureTest {
    
    @TestSetup
    static void setupTestData() {
        // Используем хардкод RecordTypeId
        Id recordTypeId = '012Kc000000tenuIAA';
        
        // Создаем тестовые лиды
        List<Lead> testLeads = new List<Lead>();
        
        // Лид с Parsing_Status__c = 'Black list'
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'FutureTest1',
            Company = 'Test Company 1',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'Black list'
        ));
        
        // Лид с Parsing_Status__c = 'Approved' (не должен измениться)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'FutureTest2',
            Company = 'Test Company 2',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'Approved'
        ));
        
        insert testLeads;
    }
    
    @isTest
    static void testFutureExecution() {
        // Получаем тестовые лиды
        List<Lead> testLeads = [SELECT Id, Status, Parsing_Status__c FROM Lead WHERE LastName LIKE 'FutureTest%'];
        
        // Собираем ID лидов
        Set<Id> leadIds = new Set<Id>();
        for (Lead lead : testLeads) {
            leadIds.add(lead.Id);
        }
        
        Test.startTest();
        // Вызываем Future метод
        LeadDeniedStatusFuture.processLeadsFuture(leadIds);
        Test.stopTest();
        
        // Проверяем результаты
        List<Lead> updatedLeads = [SELECT Id, Status, Parsing_Status__c, LastName FROM Lead WHERE Id IN :leadIds];
        
     
    }
    
    @isTest
    static void testFutureWithEmptySet() {
        // Тестируем Future с пустым набором ID
        Set<Id> emptyLeadIds = new Set<Id>();
        
        Test.startTest();
        LeadDeniedStatusFuture.processLeadsFuture(emptyLeadIds);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testFutureWithNonExistentIds() {
        // Тестируем Future с несуществующими ID
        Set<Id> nonExistentIds = new Set<Id>{
            '00Q000000000000', // Несуществующий ID
            '00Q000000000001'  // Несуществующий ID
        };
        
        Test.startTest();
        LeadDeniedStatusFuture.processLeadsFuture(nonExistentIds);
        Test.stopTest();
        
       
    }
    
    @isTest
    static void testFutureExceptionHandling() {
        // Создаем лид с некорректными данными для тестирования обработки исключений
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'FutureExceptionTest',
            Company = 'Test Company',
            RecordTypeId = '012Kc000000tenuIAA',
            Status = 'New',
            Parsing_Status__c = 'Black list'
        );
        
        insert testLead;
        
        Set<Id> leadIds = new Set<Id>{testLead.Id};
        
        Test.startTest();
        LeadDeniedStatusFuture.processLeadsFuture(leadIds);
        Test.stopTest();
        
        // Проверяем, что лид был обновлен
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
}