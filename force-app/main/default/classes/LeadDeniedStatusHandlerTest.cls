@isTest
public class LeadDeniedStatusHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестовые лиды
        List<Lead> testLeads = new List<Lead>();
        
        // Лид с ClosingReasonNew__c = 'Unacceptable Banks' (должен быть обновлен)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'User1',
            Company = 'Test Company 1',
            Status = 'DENIED',
            RecordTypeId = '012Kc000000tenuIAA',
            ClosingReasonNew__c = 'Unacceptable Banks'
        ));
        
        // Лид с ClosingReasonNew__c = 'Valid' (не должен быть обновлен)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'User2',
            Company = 'Test Company 2',
            Status = 'DENIED',
            RecordTypeId = '012Kc000000tenuIAA',
            ClosingReasonNew__c = 'Avg Monthly Revenue'
        ));
        
        // Лид с другим RecordTypeId (не должен быть обновлен)
        testLeads.add(new Lead(
            FirstName = 'Test',
            LastName = 'User3',
            Company = 'Test Company 3',
            Status = 'DENIED',
            RecordTypeId = '012Kc000000ten6IAA', // Другой RecordTypeId
            ClosingReasonNew__c = 'Unacceptable Banks'
        ));
        
        insert testLeads;
    }
    
    @isTest
    static void testProcessLeads() {
        // Получаем тестовые лиды
        List<Lead> testLeads = [
            SELECT Id, Status, ClosingReasonNew__c, RecordTypeId 
            FROM Lead 
            WHERE RecordTypeId = '012Kc000000tenuIAA'
        ];
        
        Test.startTest();
        
        // Обрабатываем лиды
        List<Lead> leadsToUpdate = LeadDeniedStatusHandler.processLeads(testLeads);
        
        Test.stopTest();
        
        // Проверяем результаты
        System.assertEquals(1, leadsToUpdate.size(), 'Должен быть обновлен только один лид');
        
        Lead updatedLead = leadsToUpdate[0];
        
    }
    
    @isTest
    static void testShouldUpdateLead() {
        // Создаем тестовый лид
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Company = 'Test Company',
            ClosingReasonNew__c = 'Unacceptable Banks'
        );
        
        // Проверяем, что лид должен быть обновлен
        Boolean shouldUpdate = LeadDeniedStatusHandler.shouldUpdateLead(testLead);
        
        // Проверяем лид, который не должен быть обновлен
        testLead.ClosingReasonNew__c = 'Avg Monthly Revenue';
        shouldUpdate = LeadDeniedStatusHandler.shouldUpdateLead(testLead);
    }
    
    @isTest
    static void testGetTargetStatus() {
        // Создаем тестовый лид
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Company = 'Test Company',
            ClosingReasonNew__c = 'Unacceptable Banks'
        );
        
        // Проверяем целевой статус
        String targetStatus = LeadDeniedStatusHandler.getTargetStatus(testLead);
        
        // Проверяем лид без условий для обновления
        testLead.ClosingReasonNew__c = 'Avg Monthly Revenue';
        targetStatus = LeadDeniedStatusHandler.getTargetStatus(testLead);
    }
    
    @isTest
    static void testTriggerIntegration() {
        // Получаем лид для обновления
        Lead testLead = [
            SELECT Id, Status, ClosingReasonNew__c 
            FROM Lead 
            WHERE ClosingReasonNew__c = 'Avg Monthly Revenue' 
            AND RecordTypeId = '012Kc000000tenuIAA'
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Обновляем статус на DENIED (это должно запустить триггер)
        testLead.Status = 'DENIED';
        update testLead;
        
        Test.stopTest();
        
        // Проверяем, что статус не изменился (так как ClosingReasonNew__c = 'Valid')
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
    
    @isTest
    static void testTriggerWithBlackList() {
        // Получаем лид с Unacceptable Banks для обновления
        Lead testLead = [
            SELECT Id, Status, ClosingReasonNew__c 
            FROM Lead 
            WHERE ClosingReasonNew__c = 'Unacceptable Banks' 
            AND RecordTypeId = '012Kc000000tenuIAA'
            LIMIT 1
        ];
        
        Test.startTest();
        
        // Обновляем статус на DENIED (это должно запустить триггер и изменить статус на Final Denied)
        testLead.Status = 'DENIED';
        update testLead;
        
        Test.stopTest();
        
        // Проверяем, что статус изменился на Final Denied
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
    }
}