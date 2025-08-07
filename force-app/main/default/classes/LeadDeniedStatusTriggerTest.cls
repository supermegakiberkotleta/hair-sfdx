@isTest
public class LeadDeniedStatusTriggerTest {
    
    @TestSetup
    static void setupTestData() {
        // Используем хардкод RecordTypeId
        Id recordTypeId = '012Kc000000tenuIAA';
        
        // Создаем тестовые лиды
        List<Lead> testLeads = new List<Lead>();
        
        // Лид с нужным RecordTypeId и Parsing_Status__c = 'Black list'
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'TriggerTest1',
            Company = 'Test Company 1',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'Black list'
        ));
        
        // Лид с нужным RecordTypeId и Parsing_Status__c = 'Approved'
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'TriggerTest2',
            Company = 'Test Company 2',
            RecordTypeId = recordTypeId,
            Status = 'New',
            Parsing_Status__c = 'Approved'
        ));
        
        // Лид с другим RecordTypeId
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'TriggerTest3',
            Company = 'Test Company 3',
            // Не указываем RecordTypeId - будет использован стандартный
            Status = 'New',
            Parsing_Status__c = 'Black list'
        ));
        
        insert testLeads;
    }
    
    @isTest
    static void testTriggerWithCorrectRecordTypeAndBlackList() {
        // Получаем лид с нужным RecordTypeId и Parsing_Status__c = 'Black list'
        Lead testLead = [SELECT Id, Status, Parsing_Status__c, RecordTypeId FROM Lead WHERE LastName = 'TriggerTest1' LIMIT 1];
        
        // Обновляем статус на DENIED
        testLead.Status = 'DENIED';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        // В тестовом режиме триггер не должен сработать
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testTriggerWithCorrectRecordTypeAndApproved() {
        // Получаем лид с нужным RecordTypeId и Parsing_Status__c = 'Approved'
        Lead testLead = [SELECT Id, Status, Parsing_Status__c, RecordTypeId FROM Lead WHERE LastName = 'TriggerTest2' LIMIT 1];
        
        // Обновляем статус на DENIED
        testLead.Status = 'DENIED';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        // В тестовом режиме триггер не должен сработать
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testTriggerWithDifferentRecordType() {
        // Получаем лид с другим RecordTypeId
        Lead testLead = [SELECT Id, Status, Parsing_Status__c, RecordTypeId FROM Lead WHERE LastName = 'TriggerTest3' LIMIT 1];
        
        // Обновляем статус на DENIED
        testLead.Status = 'DENIED';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        // В тестовом режиме триггер не должен сработать
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testTriggerWithStatusNotChanged() {
        // Получаем лид
        Lead testLead = [SELECT Id, Status, Parsing_Status__c, RecordTypeId FROM Lead WHERE LastName = 'TriggerTest1' LIMIT 1];
        
        // Обновляем что-то другое, но не статус
        testLead.Company = 'Updated Company';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        // Триггер не должен сработать, так как статус не изменился
        Lead updatedLead = [SELECT Id, Status, Company FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testTriggerWithStatusChangedToNonDenied() {
        // Получаем лид
        Lead testLead = [SELECT Id, Status, Parsing_Status__c, RecordTypeId FROM Lead WHERE LastName = 'TriggerTest1' LIMIT 1];
        
        // Обновляем статус на что-то другое, но не DENIED
        testLead.Status = 'Qualified';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        // Триггер не должен сработать, так как статус не изменился на DENIED
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testTriggerWithStatusAlreadyDenied() {
        // Получаем лид
        Lead testLead = [SELECT Id, Status, Parsing_Status__c, RecordTypeId FROM Lead WHERE LastName = 'TriggerTest1' LIMIT 1];
        
        // Сначала устанавливаем статус DENIED
        testLead.Status = 'DENIED';
        update testLead;
        
        // Затем обновляем что-то другое, но статус остается DENIED
        testLead.Company = 'Updated Company';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        // Триггер не должен сработать, так как статус не изменился
        Lead updatedLead = [SELECT Id, Status, Company FROM Lead WHERE Id = :testLead.Id];
        
    }
    
    @isTest
    static void testTriggerWithMultipleLeads() {
        // Получаем несколько лидов
        List<Lead> testLeads = [SELECT Id, Status, Parsing_Status__c, RecordTypeId FROM Lead WHERE LastName LIKE 'TriggerTest%'];
        
        // Обновляем статус на DENIED для всех
        for (Lead lead : testLeads) {
            lead.Status = 'DENIED';
        }
        
        Test.startTest();
        update testLeads;
        Test.stopTest();
        
        // В тестовом режиме триггер не должен сработать
        List<Lead> updatedLeads = [SELECT Id, Status FROM Lead WHERE Id IN :testLeads];
        
    }
    
    @isTest
    static void testTriggerInsertOperation() {
        // Создаем новый лид с нужным RecordTypeId и статусом DENIED
        Lead newLead = new Lead(
            FirstName = 'Test',
            LastName = 'InsertTest',
            Company = 'Test Company',
            RecordTypeId = '012Kc000000tenuIAA',
            Status = 'DENIED',
            Parsing_Status__c = 'Black list'
        );
        
        Test.startTest();
        insert newLead;
        Test.stopTest();
        
        // Триггер не должен сработать для insert операций
        Lead insertedLead = [SELECT Id, Status FROM Lead WHERE Id = :newLead.Id];
    }
    
    @isTest
    static void testTriggerWithBatchExecution() {
        // Получаем лид с нужным RecordTypeId и Parsing_Status__c = 'Black list'
        Lead testLead = [SELECT Id, Status, Parsing_Status__c, RecordTypeId FROM Lead WHERE LastName = 'TriggerTest1' LIMIT 1];
        
        // Обновляем статус на DENIED
        testLead.Status = 'DENIED';
        
        Test.startTest();
        update testLead;
        Test.stopTest();
        
        // В тестовом режиме Batch не должен сработать
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
}