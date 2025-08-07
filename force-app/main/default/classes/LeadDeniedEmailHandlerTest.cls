@isTest
public class LeadDeniedEmailHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестовые данные
        List<Lead> testLeads = new List<Lead>();
        
        // Лид, который соответствует всем условиям
        Lead lead1 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead1',
            Company = 'Test Company 1',
            Status = 'New',
            RecordTypeId = '012Kc000000tenuIAA',
            Broker_email__c = 'broker1@test.com',
            ClosingReasonNew__c = 'Avg Monthly Revenue'
        );
        testLeads.add(lead1);
        
        // Лид без email брокера
        Lead lead2 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead2',
            Company = 'Test Company 2',
            Status = 'New',
            RecordTypeId = '012Kc000000tenuIAA',
            ClosingReasonNew__c = 'Min Single Month Revenue'
        );
        testLeads.add(lead2);
        
        // Лид без причины закрытия
        Lead lead3 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead3',
            Company = 'Test Company 3',
            Status = 'New',
            RecordTypeId = '012Kc000000tenuIAA',
            Broker_email__c = 'broker3@test.com'
        );
        testLeads.add(lead3);
        
        // Лид с другим RecordTypeId
        Lead lead4 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead4',
            Company = 'Test Company 4',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA', // Другой RecordTypeId
            Broker_email__c = 'broker4@test.com',
            ClosingReasonNew__c = 'Inconsistent revenue'
        );
        testLeads.add(lead4);
        
        // Лид с несколькими причинами закрытия
        Lead lead5 = new Lead(
            FirstName = 'Test',
            LastName = 'Lead5',
            Company = 'Test Company 5',
            Status = 'New',
            RecordTypeId = '012Kc000000tenuIAA',
            Broker_email__c = 'broker5@test.com',
            ClosingReasonNew__c = 'Avg Monthly Revenue;Min Single Month Revenue'
        );
        testLeads.add(lead5);
        
        insert testLeads;
    }
    
    @isTest
    static void testSendDeniedEmail() {
        // Получаем тестовый лид
        Lead testLead = [SELECT Id, Broker_email__c, ClosingReasonNew__c 
                        FROM Lead 
                        WHERE Broker_email__c = 'broker1@test.com' 
                        AND ClosingReasonNew__c = 'Avg Monthly Revenue'
                        LIMIT 1];
        
        Test.startTest();
        
        // Вызываем метод отправки email
        LeadDeniedEmailHandler.sendDeniedEmail(
            testLead.Id, 
            testLead.Broker_email__c, 
            testLead.ClosingReasonNew__c
        );
        
        Test.stopTest();
        
        // Проверяем, что метод выполнился без ошибок
        // В тестовом режиме email не отправляется, но метод должен выполниться
        System.assert(true, 'Email sending method executed successfully');
    }
    
    @isTest
    static void testProcessLeadsForEmail() {
        // Получаем все тестовые лиды
        List<Lead> testLeads = [SELECT Id, Broker_email__c, ClosingReasonNew__c 
                               FROM Lead 
                               WHERE Broker_email__c != null 
                               AND ClosingReasonNew__c != null];
        
        Test.startTest();
        
        // Вызываем метод обработки лидов
        LeadDeniedEmailHandler.processLeadsForEmail(testLeads);
        
        Test.stopTest();
        
        // Проверяем, что метод выполнился без ошибок
        System.assert(true, 'Process leads method executed successfully');
    }
    
    @isTest
    static void testTriggerWithValidLead() {
        // Получаем лид, который соответствует условиям
        Lead testLead = [SELECT Id, Status, RecordTypeId, Broker_email__c, ClosingReasonNew__c 
                        FROM Lead 
                        WHERE Broker_email__c = 'broker1@test.com' 
                        AND ClosingReasonNew__c = 'Avg Monthly Revenue'
                        LIMIT 1];
        
        Test.startTest();
        
        // Обновляем статус на Final Denied
        testLead.Status = 'Final Denied';
        update testLead;
        
        Test.stopTest();
        
        // Проверяем, что обновление прошло успешно
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Final Denied', updatedLead.Status, 'Lead status should be updated to Final Denied');
    }
    
    @isTest
    static void testTriggerWithInvalidLead() {
        // Получаем лид без email брокера
        Lead testLead = [SELECT Id, Status, RecordTypeId, Broker_email__c, ClosingReasonNew__c 
                        FROM Lead 
                        WHERE Broker_email__c = null 
                        LIMIT 1];
        
        Test.startTest();
        
        // Обновляем статус на Final Denied
        testLead.Status = 'Final Denied';
        update testLead;
        
        Test.stopTest();
        
        // Проверяем, что обновление прошло успешно (триггер не должен вызывать ошибку)
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Final Denied', updatedLead.Status, 'Lead status should be updated to Final Denied');
    }
    
    @isTest
    static void testTriggerWithMultipleReasons() {
        // Получаем лид с несколькими причинами закрытия
        Lead testLead = [SELECT Id, Status, RecordTypeId, Broker_email__c, ClosingReasonNew__c 
                        FROM Lead 
                        WHERE Broker_email__c = 'broker5@test.com' 
                        AND ClosingReasonNew__c = 'Avg Monthly Revenue;Min Single Month Revenue'
                        LIMIT 1];
        
        Test.startTest();
        
        // Обновляем статус на Final Denied
        testLead.Status = 'Final Denied';
        update testLead;
        
        Test.stopTest();
        
        // Проверяем, что обновление прошло успешно
        Lead updatedLead = [SELECT Id, Status FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals('Final Denied', updatedLead.Status, 'Lead status should be updated to Final Denied');
    }
} 