@isTest
public class UnifiedLeadProcessorTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестовые лиды
        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            testLeads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Company = 'Test Company ' + i,
                Status = 'Open - Not Contacted',
                Email = 'test' + i + '@example.com'
            ));
        }
        insert testLeads;
    }
    
    @isTest
    static void testUnifiedProcessorWithInsert() {
        // Получаем созданные лиды
        List<Lead> leads = [SELECT Id, Status FROM Lead];
        System.assertEquals(5, leads.size());
        
        // Создаем данные для тестирования
        Set<Id> leadIds = new Set<Id>();
        Map<Id, String> statusMap = new Map<Id, String>();
        List<Map<String, Object>> webhookData = new List<Map<String, Object>>();
        
        for (Lead lead : leads) {
            leadIds.add(lead.Id);
            statusMap.put(lead.Id, lead.Status);
        }
        
        Test.startTest();
        
        // Создаем и запускаем UnifiedLeadProcessor
        UnifiedLeadProcessor processor = new UnifiedLeadProcessor(
            leadIds, 
            statusMap, 
            webhookData, 
            true // isInsert
        );
        
        // В тестовом режиме не запускаем System.enqueueJob, а вызываем execute напрямую
        processor.execute(null);
        
        Test.stopTest();
        
        // Проверяем, что создались записи истории статусов
        List<Lead_Status_History__c> historyRecords = [
            SELECT Id, Lead__c, Status__c, Is_First_History__c 
            FROM Lead_Status_History__c 
            WHERE Lead__c IN :leadIds
        ];
        
        System.assertEquals(5, historyRecords.size(), 'Должно быть создано 5 записей истории');
        
        // Проверяем, что у одной записи Is_First_History__c = true для каждого лида
        Map<Id, List<Lead_Status_History__c>> historyByLead = new Map<Id, List<Lead_Status_History__c>>();
        for (Lead_Status_History__c history : historyRecords) {
            if (!historyByLead.containsKey(history.Lead__c)) {
                historyByLead.put(history.Lead__c, new List<Lead_Status_History__c>());
            }
            historyByLead.get(history.Lead__c).add(history);
        }
        
        for (Id leadId : leadIds) {
            List<Lead_Status_History__c> leadHistory = historyByLead.get(leadId);
            System.assertEquals(1, leadHistory.size(), 'У каждого лида должна быть одна запись истории');
            System.assertEquals(true, leadHistory[0].Is_First_History__c, 'Первая запись должна быть помечена как первая');
        }
    }
    
    @isTest
    static void testUnifiedProcessorWithUpdate() {
        // Получаем созданные лиды
        List<Lead> leads = [SELECT Id, Status FROM Lead];
        
        // Обновляем статус лидов
        for (Lead lead : leads) {
            lead.Status = 'Working - Contacted';
        }
        update leads;
        
        // Создаем данные для тестирования обновления
        Set<Id> leadIds = new Set<Id>();
        Map<Id, String> statusMap = new Map<Id, String>();
        List<Map<String, Object>> webhookData = new List<Map<String, Object>>();
        
        for (Lead lead : leads) {
            leadIds.add(lead.Id);
            statusMap.put(lead.Id, lead.Status);
            
            // Создаем данные для webhook
            Map<String, Object> webhookRecord = new Map<String, Object>();
            webhookRecord.put('Id', lead.Id);
            webhookRecord.put('Status', lead.Status);
            webhookData.add(webhookRecord);
        }
        
        Test.startTest();
        
        // Создаем и запускаем UnifiedLeadProcessor
        UnifiedLeadProcessor processor = new UnifiedLeadProcessor(
            leadIds, 
            statusMap, 
            webhookData, 
            false // isUpdate
        );
        
        // В тестовом режиме не запускаем System.enqueueJob, а вызываем execute напрямую
        processor.execute(null);
        
        Test.stopTest();
        
        // Проверяем, что создались новые записи истории статусов
        List<Lead_Status_History__c> historyRecords = [
            SELECT Id, Lead__c, Status__c, Is_First_History__c 
            FROM Lead_Status_History__c 
            WHERE Lead__c IN :leadIds
            ORDER BY Lead__c, Date__c ASC
        ];
        
        System.assertEquals(10, historyRecords.size(), 'Должно быть создано 10 записей истории (5 исходных + 5 обновлений)');
        
        // Проверяем, что поле Status_History__c обновилось на лидах
        List<Lead> updatedLeads = [SELECT Id, Status_History__c FROM Lead WHERE Id IN :leadIds];
        for (Lead lead : updatedLeads) {
            System.assertNotEquals(null, lead.Status_History__c, 'Поле Status_History__c должно быть заполнено');
            System.assert(lead.Status_History__c.contains('Open - Not Contacted'), 'История должна содержать исходный статус');
            System.assert(lead.Status_History__c.contains('Working - Contacted'), 'История должна содержать новый статус');
        }
    }
    
    @isTest
    static void testUnifiedProcessorWithEmptyData() {
        Test.startTest();
        
        // Создаем UnifiedLeadProcessor с пустыми данными
        UnifiedLeadProcessor processor = new UnifiedLeadProcessor(
            new Set<Id>(), 
            new Map<Id, String>(), 
            new List<Map<String, Object>>(), 
            false
        );
        
        // Вызываем execute - не должно быть ошибок
        processor.execute(null);
        
        Test.stopTest();
        
        // Проверяем, что никаких записей истории не создалось
        List<Lead_Status_History__c> historyRecords = [SELECT Id FROM Lead_Status_History__c];
        System.assertEquals(0, historyRecords.size(), 'Не должно быть создано записей истории при пустых данных');
    }
    
    @isTest
    static void testUnifiedProcessorWithException() {
        // Создаем данные с невалидными ID для тестирования обработки ошибок
        Set<Id> invalidLeadIds = new Set<Id>();
        Map<Id, String> statusMap = new Map<Id, String>();
        List<Map<String, Object>> webhookData = new List<Map<String, Object>>();
        
        // Добавляем несуществующий ID
        invalidLeadIds.add('001000000000000'); // Несуществующий ID
        statusMap.put('001000000000000', 'Test Status');
        
        Test.startTest();
        
        // Создаем и запускаем UnifiedLeadProcessor
        UnifiedLeadProcessor processor = new UnifiedLeadProcessor(
            invalidLeadIds, 
            statusMap, 
            webhookData, 
            true
        );
        
        // Вызываем execute - не должно быть необработанных исключений
        try {
            processor.execute(null);
        } catch (Exception e) {
            System.assert(false, 'UnifiedLeadProcessor должен обрабатывать исключения внутри себя: ' + e.getMessage());
        }
        
        Test.stopTest();
        
        // Проверяем, что никаких записей истории не создалось
        List<Lead_Status_History__c> historyRecords = [SELECT Id FROM Lead_Status_History__c];
        System.assertEquals(0, historyRecords.size(), 'Не должно быть создано записей истории при невалидных данных');
    }
}
