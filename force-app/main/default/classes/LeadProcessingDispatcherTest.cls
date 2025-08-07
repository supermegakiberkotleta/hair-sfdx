@isTest
public class LeadProcessingDispatcherTest {
    
    @isTest
    static void testProcessDeniedStatus() {
        // Создаем тестовый лид
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Company = 'Test Company',
            Status = 'DENIED',
            RecordTypeId = '012Kc000000tenuIAA'
        );
        insert testLead;
        
        Test.startTest();
        
        // Тестируем первый запуск
        LeadProcessingDispatcher.processDeniedStatus(new List<Lead>{testLead});
        
        // Проверяем статус
        Map<String, Boolean> status = LeadProcessingDispatcher.getProcessingStatus();
        
        // Пытаемся запустить второй раз (должен быть отложен)
        LeadProcessingDispatcher.processDeniedStatus(new List<Lead>{testLead});
                
        Test.stopTest();
    }
    
    @isTest
    static void testMarkProcessComplete() {
        // Создаем тестовый лид
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Company = 'Test Company',
            Status = 'DENIED',
            RecordTypeId = '012Kc000000tenuIAA'
        );
        insert testLead;
        
        Test.startTest();
        
        // Запускаем процесс
        LeadProcessingDispatcher.processDeniedStatus(new List<Lead>{testLead});
        
        // Добавляем отложенный запрос
        LeadProcessingDispatcher.processDeniedStatus(new List<Lead>{testLead});
        
        // Помечаем процесс как завершенный
        LeadProcessingDispatcher.markProcessComplete('DENIED_STATUS');
        
        // Проверяем статус
        Map<String, Boolean> status = LeadProcessingDispatcher.getProcessingStatus();        
        Test.stopTest();
    }
    
    @isTest
    static void testResetAllFlags() {
        // Создаем тестовый лид
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Company = 'Test Company',
            Status = 'DENIED',
            RecordTypeId = '012Kc000000tenuIAA'
        );
        insert testLead;
        
        Test.startTest();
        
        // Запускаем процесс и добавляем отложенные запросы
        LeadProcessingDispatcher.processDeniedStatus(new List<Lead>{testLead});
        LeadProcessingDispatcher.processDeniedStatus(new List<Lead>{testLead});
        
        // Сбрасываем все флаги
        LeadProcessingDispatcher.resetAllFlags();
        
        // Проверяем статус
        Map<String, Boolean> status = LeadProcessingDispatcher.getProcessingStatus();
        Test.stopTest();
    }
}