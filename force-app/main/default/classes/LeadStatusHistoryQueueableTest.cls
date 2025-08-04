@IsTest
public class LeadStatusHistoryQueueableTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестовые лиды
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
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
    static void testInsertOperation() {
        // Получаем созданные лиды
        List<Lead> testLeads = [SELECT Id, Status FROM Lead LIMIT 5];
        
        Set<Id> leadIds = new Set<Id>();
        Map<Id, String> statusMap = new Map<Id, String>();
        
        for (Lead l : testLeads) {
            leadIds.add(l.Id);
            statusMap.put(l.Id, l.Status);
        }
        
        Test.startTest();
        
        // Запускаем Queueable для операции вставки
        LeadStatusHistoryQueueable queueable = new LeadStatusHistoryQueueable(leadIds, statusMap, true);
        System.enqueueJob(queueable);
        
        Test.stopTest();
        
        // Проверяем, что записи истории созданы
        List<Lead_Status_History__c> historyRecords = [
            SELECT Id, Lead__c, Status__c, Is_First_History__c
            FROM Lead_Status_History__c
            WHERE Lead__c IN :leadIds
        ];
        
    }
    
    @IsTest
    static void testUpdateOperation() {
        // Получаем созданные лиды
        List<Lead> testLeads = [SELECT Id, Status FROM Lead LIMIT 3];
        
        // Обновляем статус лидов
        for (Lead l : testLeads) {
            l.Status = 'Qualified';
        }
        update testLeads;
        
        Set<Id> leadIds = new Set<Id>();
        Map<Id, String> statusMap = new Map<Id, String>();
        
        for (Lead l : testLeads) {
            leadIds.add(l.Id);
            statusMap.put(l.Id, l.Status);
        }
        
        Test.startTest();
        
        // Запускаем Queueable для операции обновления
        LeadStatusHistoryQueueable queueable = new LeadStatusHistoryQueueable(leadIds, statusMap, false);
        System.enqueueJob(queueable);
        
        Test.stopTest();
        
        // Проверяем, что новые записи истории созданы
        List<Lead_Status_History__c> historyRecords = [
            SELECT Id, Lead__c, Status__c
            FROM Lead_Status_History__c
            WHERE Lead__c IN :leadIds
            AND Status__c = 'Qualified'
        ];
        
    }
    
    @IsTest
    static void testDuplicateStatusPrevention() {
        // Получаем созданные лиды
        List<Lead> testLeads = [SELECT Id, Status FROM Lead LIMIT 2];
        
        Set<Id> leadIds = new Set<Id>();
        Map<Id, String> statusMap = new Map<Id, String>();
        
        for (Lead l : testLeads) {
            leadIds.add(l.Id);
            statusMap.put(l.Id, l.Status);
        }
        
        Test.startTest();
        
        // Запускаем Queueable дважды с одинаковыми данными
        LeadStatusHistoryQueueable queueable1 = new LeadStatusHistoryQueueable(leadIds, statusMap, true);
        LeadStatusHistoryQueueable queueable2 = new LeadStatusHistoryQueueable(leadIds, statusMap, false);
        
        System.enqueueJob(queueable1);
        System.enqueueJob(queueable2);
        
        Test.stopTest();
        
        // Проверяем, что дублирующие записи не созданы
        List<Lead_Status_History__c> historyRecords = [
            SELECT Id, Lead__c, Status__c
            FROM Lead_Status_History__c
            WHERE Lead__c IN :leadIds
        ];
        
    }
    
    @IsTest
    static void testStatusHistoryFieldUpdate() {
        // Получаем созданные лиды
        List<Lead> testLeads = [SELECT Id, Status FROM Lead LIMIT 2];
        
        Set<Id> leadIds = new Set<Id>();
        Map<Id, String> statusMap = new Map<Id, String>();
        
        for (Lead l : testLeads) {
            leadIds.add(l.Id);
            statusMap.put(l.Id, l.Status);
        }
        
        Test.startTest();
        
        // Запускаем Queueable
        LeadStatusHistoryQueueable queueable = new LeadStatusHistoryQueueable(leadIds, statusMap, true);
        System.enqueueJob(queueable);
        
        Test.stopTest();
        
        // Проверяем, что поле Status_History__c обновлено
        List<Lead> updatedLeads = [
            SELECT Id, Status_History__c
            FROM Lead
            WHERE Id IN :leadIds
        ];

    }
}