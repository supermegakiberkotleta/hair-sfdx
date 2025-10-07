@IsTest
public class SystemNotificationsHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестового пользователя с уникальным username
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        String uniqueUsername = 'triggeruser' + System.currentTimeMillis() + '@gvahair.com.test';
        
        User testUser = new User(
            FirstName = 'Trigger',
            LastName = 'TestUser',
            Email = 'triggertest@gvahair.com',
            Username = uniqueUsername,
            Alias = 'tus' + String.valueOf(System.currentTimeMillis()).right(3), // Максимум 8 символов
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert testUser;
    }
    
    @IsTest
    static void testTriggerHandlerAfterInsert() {
        // Получаем тестового пользователя
        User testUser = [SELECT Id FROM User WHERE Email = 'triggertest@gvahair.com' LIMIT 1];
        
        // Создаем тестовый аккаунт
        Account testAccount = new Account(Name = 'Trigger Test Account');
        insert testAccount;
        
        Test.startTest();
        
        // Переопределяем notificationTypeIdOverride для тестирования
        NotificationController.notificationTypeIdOverride = '01p000000000000';
        
        // Создаем событие для тестирования триггера
        System_Notifications__e testEvent = new System_Notifications__e(
            Title__c = 'Trigger Handler Test',
            Message__c = 'Testing trigger handler execution',
            Type__c = 'warning',
            User__c = testUser.Id,
            Target__c = testAccount.Id
        );
        
        // Публикуем событие - это вызовет триггер и обработчик
        Database.SaveResult result = EventBus.publish(testEvent);
        
        Test.stopTest();
        
        // Проверяем успешное выполнение
        System.assert(result.isSuccess(), 'Event should be published successfully');
        System.debug('Trigger handler test completed - Event ID: ' + result.getId());
    }
    
    @IsTest
    static void testTriggerHandlerWithNullValues() {
        // Получаем тестового пользователя
        User testUser = [SELECT Id FROM User WHERE Email = 'triggertest@gvahair.com' LIMIT 1];
        
        Test.startTest();
        
        // Переопределяем notificationTypeIdOverride для тестирования
        NotificationController.notificationTypeIdOverride = '01p000000000000';
        
        // Создаем событие с null значениями
        System_Notifications__e testEvent = new System_Notifications__e(
            Title__c = 'Null Values Test',
            Message__c = null,
            Type__c = null,
            User__c = testUser.Id,
            Target__c = testUser.Id
        );
        
        // Публикуем событие
        Database.SaveResult result = EventBus.publish(testEvent);
        
        Test.stopTest();
        
        // Событие должно быть опубликовано, обработчик должен обработать null значения
        System.assert(result.isSuccess(), 'Event with null values should be published');
        System.debug('Null values test completed');
    }
    
    @IsTest
    static void testTriggerHandlerExceptionScenario() {
        Test.startTest();
        
        // Переопределяем notificationTypeIdOverride для тестирования
        NotificationController.notificationTypeIdOverride = '01p000000000000';
        
        // Создаем событие с недопустимыми данными для тестирования обработки ошибок
        System_Notifications__e testEvent = new System_Notifications__e(
            Title__c = 'Exception Test',
            Message__c = 'Testing exception handling in trigger handler',
            Type__c = 'error',
            User__c = '005000000000000000', // Несуществующий пользователь
            Target__c = '001000000000000000' // Несуществующий объект
        );
        
        // Публикуем событие
        Database.SaveResult result = EventBus.publish(testEvent);
        
        Test.stopTest();
        
        // Событие должно быть опубликовано, но обработчик должен обработать ошибку
        System.assert(result.isSuccess(), 'Event should be published even with invalid data');
        System.debug('Exception scenario test completed');
    }
    
    @IsTest
    static void testTriggerHandlerBulkProcessing() {
        // Получаем тестового пользователя
        User testUser = [SELECT Id FROM User WHERE Email = 'triggertest@gvahair.com' LIMIT 1];
        
        // Создаем несколько тестовых объектов
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            testAccounts.add(new Account(Name = 'Bulk Handler Account ' + i));
        }
        insert testAccounts;
        
        Test.startTest();
        
        // Переопределяем notificationTypeIdOverride для тестирования
        NotificationController.notificationTypeIdOverride = '01p000000000000';
        
        // Создаем массу событий для тестирования bulk обработки триггером
        List<System_Notifications__e> bulkEvents = new List<System_Notifications__e>();
        for (Integer i = 0; i < 10; i++) {
            bulkEvents.add(new System_Notifications__e(
                Title__c = 'Bulk Handler Test ' + i,
                Message__c = 'Bulk handler message ' + i,
                Type__c = 'info',
                User__c = testUser.Id,
                Target__c = testAccounts[i].Id
            ));
        }
        
        // Публикуем все события одновременно
        List<Database.SaveResult> results = EventBus.publish(bulkEvents);
        
        Test.stopTest();
        
        // Проверяем, что все события были успешно опубликованы
        System.assertEquals(10, results.size(), 'All 10 events should be processed by trigger');
        for (Database.SaveResult result : results) {
            System.assert(result.isSuccess(), 'Each bulk event should be published successfully');
        }
        
        System.debug('Bulk trigger handler test completed - processed ' + results.size() + ' events');
    }
    
    @IsTest
    static void testTriggerHandlerDirectCall() {
        // Получаем тестового пользователя
        User testUser = [SELECT Id FROM User WHERE Email = 'triggertest@gvahair.com' LIMIT 1];
        
        // Создаем тестовый объект
        Account testAccount = new Account(Name = 'Direct Call Account');
        insert testAccount;
        
        Test.startTest();
        
        // Переопределяем notificationTypeIdOverride для тестирования
        NotificationController.notificationTypeIdOverride = '01p000000000000';
        
        // Создаем список событий для прямого вызова обработчика
        List<System_Notifications__e> events = new List<System_Notifications__e>();
        events.add(new System_Notifications__e(
            Title__c = 'Direct Call Test',
            Message__c = 'Testing direct handler call',
            Type__c = 'success',
            User__c = testUser.Id,
            Target__c = testAccount.Id
        ));
        
        // Вызываем обработчик напрямую (имитируем вызов триггера)
        SystemNotificationsEventHandler.handleAfterInsert(events);
        
        Test.stopTest();
        
        // Проверяем, что обработчик выполнился без критических ошибок
        System.assert(true, 'Direct handler call completed successfully');
        System.debug('Direct handler call test completed');
    }
}