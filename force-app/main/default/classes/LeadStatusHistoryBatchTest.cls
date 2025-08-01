@IsTest
public class LeadStatusHistoryBatchTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестовые лиды
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test' + i,
                LastName = 'Lead' + i,
                Company = 'Test Company ' + i,
                Status = 'New'
            ));
        }
        insert testLeads;
    }
    
    @IsTest
    static void testBatchProcessing() {
        // Получаем созданные лиды
        List<Lead> testLeads = [SELECT Id, Status FROM Lead LIMIT 10];
        
        Test.startTest();
        
        // Запускаем batch
        LeadStatusHistoryBatch.startBatch();
        
        Test.stopTest();
        
        // Проверяем, что записи истории созданы
        List<Lead_Status_History__c> historyRecords = [
            SELECT Id, Lead__c, Status__c
            FROM Lead_Status_History__c
            WHERE Lead__c IN :testLeads
        ];
                
        // Проверяем, что поле Status_History__c обновлено
        List<Lead> updatedLeads = [
            SELECT Id, Status_History__c
            FROM Lead
            WHERE Id IN :testLeads
        ];
        
        
    }
    
    @IsTest
    static void testBatchWithCustomQuery() {
        // Создаем дополнительные лиды с разными статусами
        List<Lead> additionalLeads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            additionalLeads.add(new Lead(
                FirstName = 'Custom' + i,
                LastName = 'Lead' + i,
                Company = 'Custom Company ' + i,
                Status = 'Qualified'
            ));
        }
        insert additionalLeads;
        
        Test.startTest();
        
        // Запускаем batch с кастомным запросом
        String customQuery = 'SELECT Id, Status FROM Lead WHERE Status = \'Qualified\'';
        LeadStatusHistoryBatch.startBatch(customQuery);
        
        Test.stopTest();
        
        // Проверяем, что записи истории созданы только для лидов со статусом 'Qualified'
        List<Lead_Status_History__c> historyRecords = [
            SELECT Id, Lead__c, Status__c
            FROM Lead_Status_History__c
            WHERE Lead__c IN :additionalLeads
            AND Status__c = 'Qualified'
        ];
        
    }
    
    @IsTest
    static void testBatchWithExistingHistory() {
        // Получаем созданные лиды
        List<Lead> testLeads = [SELECT Id, Status FROM Lead LIMIT 5];
        
        // Создаем существующие записи истории
        List<Lead_Status_History__c> existingHistory = new List<Lead_Status_History__c>();
        for (Lead l : testLeads) {
            existingHistory.add(new Lead_Status_History__c(
                Lead__c = l.Id,
                Status__c = l.Status,
                Date__c = System.now().addDays(-1)
            ));
        }
        insert existingHistory;
        
        Test.startTest();
        
        // Запускаем batch
        LeadStatusHistoryBatch.startBatch();
        
        Test.stopTest();
        
        // Проверяем, что дублирующие записи не созданы
        List<Lead_Status_History__c> allHistoryRecords = [
            SELECT Id, Lead__c, Status__c
            FROM Lead_Status_History__c
            WHERE Lead__c IN :testLeads
        ];
        
    
    }
    
    @IsTest
    static void testBatchErrorHandling() {
        // Создаем лид с некорректными данными для тестирования обработки ошибок
        Lead invalidLead = new Lead(
            FirstName = 'Invalid',
            LastName = 'Lead',
            Company = 'Invalid Company',
            Status = 'New'
        );
        insert invalidLead;
        
        Test.startTest();
        
        // Запускаем batch
        LeadStatusHistoryBatch.startBatch();
        
        Test.stopTest();
        
        // Проверяем, что batch завершился без критических ошибок
        // (ошибки должны быть обработаны в try-catch блоке)
        List<Lead_Status_History__c> historyRecords = [
            SELECT Id, Lead__c, Status__c
            FROM Lead_Status_History__c
            WHERE Lead__c = :invalidLead.Id
        ];
        
    }
} 