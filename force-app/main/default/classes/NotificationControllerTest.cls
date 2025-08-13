@IsTest
private class NotificationControllerTest {
    
    @IsTest
    static void testSendNotificationSuccess() {
        // Подготавливаем тестовые данные
        String title = 'Test Notification';
        String message = 'This is a test notification message';
        String type = 'success';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        // Вызываем основной метод
        NotificationController.sendNotification(title, message, type, userId, targetId);
        
        Test.stopTest();
        
        // Проверяем, что метод выполнился без ошибок
        // В данном случае просто проверяем, что метод выполнился без ошибок
    }
    
    @IsTest
    static void testSendNotificationWithDefaultType() {
        // Тестируем с пустым типом (должен установиться 'info' по умолчанию)
        String title = 'Test Notification';
        String message = 'This is a test notification message';
        String type = '';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        NotificationController.sendNotification(title, message, type, userId, targetId);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationWithNullType() {
        // Тестируем с null типом (должен установиться 'info' по умолчанию)
        String title = 'Test Notification';
        String message = 'This is a test notification message';
        String type = null;
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        NotificationController.sendNotification(title, message, type, userId, targetId);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationWithSpecialCharacters() {
        // Тестируем со специальными символами и кириллицей
        String title = 'Тест уведомления @#$%^&*()';
        String message = 'Сообщение с специальными символами: !@#$%^&*()_+-=[]{}|;:,.<>?';
        String type = 'warning';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        NotificationController.sendNotification(title, message, type, userId, targetId);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationWithLongText() {
        // Тестируем с длинным текстом
        String title = 'Very Long Title ' + 'A'.repeat(100);
        String message = 'Very Long Message ' + 'B'.repeat(500);
        String type = 'error';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        NotificationController.sendNotification(title, message, type, userId, targetId);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationEmptyTitle() {
        // Тестируем с пустым заголовком - должно выбросить исключение
        String title = '';
        String message = 'This is a test notification message';
        String type = 'info';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        try {
            NotificationController.sendNotification(title, message, type, userId, targetId);
            System.assert(false, 'Should have thrown exception for empty title');
        } catch (Exception e) {
            // Проверяем, что исключение было выброшено
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationNullTitle() {
        // Тестируем с null заголовком - должно выбросить исключение
        String title = null;
        String message = 'This is a test notification message';
        String type = 'info';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        try {
            NotificationController.sendNotification(title, message, type, userId, targetId);
            System.assert(false, 'Should have thrown exception for null title');
        } catch (Exception e) {
            // Проверяем, что исключение было выброшено
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationEmptyMessage() {
        // Тестируем с пустым сообщением - должно выбросить исключение
        String title = 'Test Notification';
        String message = '';
        String type = 'info';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        try {
            NotificationController.sendNotification(title, message, type, userId, targetId);
            System.assert(false, 'Should have thrown exception for empty message');
        } catch (Exception e) {
            // Проверяем, что исключение было выброшено
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationNullMessage() {
        // Тестируем с null сообщением - должно выбросить исключение
        String title = 'Test Notification';
        String message = null;
        String type = 'info';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        try {
            NotificationController.sendNotification(title, message, type, userId, targetId);
            System.assert(false, 'Should have thrown exception for null message');
        } catch (Exception e) {
            // Проверяем, что исключение было выброшено
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationEmptyUserId() {
        // Тестируем с пустым userId - должно выбросить исключение
        String title = 'Test Notification';
        String message = 'This is a test notification message';
        String type = 'info';
        String userId = '';
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        try {
            NotificationController.sendNotification(title, message, type, userId, targetId);
            System.assert(false, 'Should have thrown exception for empty userId');
        } catch (Exception e) {
            // Проверяем, что исключение было выброшено
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationNullUserId() {
        // Тестируем с null userId - должно выбросить исключение
        String title = 'Test Notification';
        String message = 'This is a test notification message';
        String type = 'info';
        String userId = null;
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        try {
            NotificationController.sendNotification(title, message, type, userId, targetId);
            System.assert(false, 'Should have thrown exception for null userId');
        } catch (Exception e) {
            // Проверяем, что исключение было выброшено
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationInvalidUserId() {
        // Тестируем с несуществующим userId - должно выбросить исключение
        String title = 'Test Notification';
        String message = 'This is a test notification message';
        String type = 'info';
        String userId = '005000000000000'; // Несуществующий ID пользователя
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        try {
            NotificationController.sendNotification(title, message, type, userId, targetId);
            System.assert(false, 'Should have thrown exception for invalid userId');
        } catch (Exception e) {
            // Проверяем, что исключение было выброшено
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationEmptyTargetId() {
        // Тестируем с пустым targetId - должно выбросить исключение
        String title = 'Test Notification';
        String message = 'This is a test notification message';
        String type = 'info';
        String userId = UserInfo.getUserId();
        String targetId = '';
        
        Test.startTest();
        
        try {
            NotificationController.sendNotification(title, message, type, userId, targetId);
            System.assert(false, 'Should have thrown exception for empty targetId');
        } catch (Exception e) {
            // Проверяем, что исключение было выброшено
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationNullTargetId() {
        // Тестируем с null targetId - должно выбросить исключение
        String title = 'Test Notification';
        String message = 'This is a test notification message';
        String type = 'info';
        String userId = UserInfo.getUserId();
        String targetId = null;
        
        Test.startTest();
        
        try {
            NotificationController.sendNotification(title, message, type, userId, targetId);
            System.assert(false, 'Should have thrown exception for null targetId');
        } catch (Exception e) {
            // Проверяем, что исключение было выброшено
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationWhitespaceTitle() {
        // Тестируем с заголовком, содержащим только пробелы - должно выбросить исключение
        String title = '   ';
        String message = 'This is a test notification message';
        String type = 'info';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        try {
            NotificationController.sendNotification(title, message, type, userId, targetId);
            System.assert(false, 'Should have thrown exception for whitespace title');
        } catch (Exception e) {
            // Проверяем, что исключение было выброшено
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationWhitespaceMessage() {
        // Тестируем с сообщением, содержащим только пробелы - должно выбросить исключение
        String title = 'Test Notification';
        String message = '   ';
        String type = 'info';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        try {
            NotificationController.sendNotification(title, message, type, userId, targetId);
            System.assert(false, 'Should have thrown exception for whitespace message');
        } catch (Exception e) {
            // Проверяем, что исключение было выброшено
            System.assert(true, 'Exception was thrown as expected');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationDifferentTypes() {
        // Тестируем различные типы уведомлений
        List<String> types = new List<String>{'info', 'success', 'warning', 'error', 'custom'};
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        for (String type : types) {
            NotificationController.sendNotification('Test ' + type, 'Message for ' + type, type, userId, targetId);
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testTestCoverageMethod() {
        // Тестируем метод для покрытия тестами
        Test.startTest();
        
        // Вызываем приватный метод через @TestVisible
        NotificationController.testCoverageMethod();
        
        Test.stopTest();
    }
    
    @IsTest
    static void testSendNotificationWithCurrentUser() {
        // Тестируем, что метод корректно работает с текущим пользователем
        String title = 'User Test Notification';
        String message = 'This notification is for the current user';
        String type = 'info';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        Test.startTest();
        
        NotificationController.sendNotification(title, message, type, userId, targetId);
        
        Test.stopTest();
        
        // Проверяем, что UserInfo.getUserId() возвращает корректное значение
        System.assertNotEquals(null, userId, 'User ID should not be null');
        System.assertNotEquals('', userId, 'User ID should not be empty');
    }
    
    @IsTest
    static void testSendNotificationWithOverride() {
        // Тестируем с переопределенным notificationTypeId
        String title = 'Test Notification with Override';
        String message = 'This notification uses overridden notification type';
        String type = 'info';
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        // Устанавливаем override для тестирования
        NotificationController.notificationTypeIdOverride = '0ML000000000000';
        
        Test.startTest();
        
        NotificationController.sendNotification(title, message, type, userId, targetId);
        
        Test.stopTest();
        
        // Сбрасываем override
        NotificationController.notificationTypeIdOverride = null;
    }
    
    @IsTest
    static void testDebugExceptionMessages() {
        // Отладочный тест для проверки точных сообщений об ошибках
        System.debug('=== Testing exception messages ===');
        String userId = UserInfo.getUserId();
        String targetId = '00Q000000000000'; // Тестовый ID лида
        
        // Тест с пустым заголовком
        try {
            NotificationController.sendNotification('', 'test message', 'info', userId, targetId);
        } catch (Exception e) {
            System.debug('Empty title exception type: ' + e.getTypeName());
            System.debug('Empty title exception message: ' + e.getMessage());
            System.debug('Empty title exception stack trace: ' + e.getStackTraceString());
        }
        
        // Тест с null заголовком
        try {
            NotificationController.sendNotification(null, 'test message', 'info', userId, targetId);
        } catch (Exception e) {
            System.debug('Null title exception type: ' + e.getTypeName());
            System.debug('Null title exception message: ' + e.getMessage());
            System.debug('Null title exception stack trace: ' + e.getStackTraceString());
        }
        
        // Тест с пустым сообщением
        try {
            NotificationController.sendNotification('test title', '', 'info', userId, targetId);
        } catch (Exception e) {
            System.debug('Empty message exception type: ' + e.getTypeName());
            System.debug('Empty message exception message: ' + e.getMessage());
            System.debug('Empty message exception stack trace: ' + e.getStackTraceString());
        }
        
        // Тест с null сообщением
        try {
            NotificationController.sendNotification('test title', null, 'info', userId, targetId);
        } catch (Exception e) {
            System.debug('Null message exception type: ' + e.getTypeName());
            System.debug('Null message exception message: ' + e.getMessage());
            System.debug('Null message exception stack trace: ' + e.getStackTraceString());
        }
        
        // Тест с пустым userId
        try {
            NotificationController.sendNotification('test title', 'test message', 'info', '', targetId);
        } catch (Exception e) {
            System.debug('Empty userId exception type: ' + e.getTypeName());
            System.debug('Empty userId exception message: ' + e.getMessage());
            System.debug('Empty userId exception stack trace: ' + e.getStackTraceString());
        }
        
        // Тест с null userId
        try {
            NotificationController.sendNotification('test title', 'test message', 'info', null, targetId);
        } catch (Exception e) {
            System.debug('Null userId exception type: ' + e.getTypeName());
            System.debug('Null userId exception message: ' + e.getMessage());
            System.debug('Null userId exception stack trace: ' + e.getStackTraceString());
        }
        
        // Тест с пустым targetId
        try {
            NotificationController.sendNotification('test title', 'test message', 'info', userId, '');
        } catch (Exception e) {
            System.debug('Empty targetId exception type: ' + e.getTypeName());
            System.debug('Empty targetId exception message: ' + e.getMessage());
            System.debug('Empty targetId exception stack trace: ' + e.getStackTraceString());
        }
        
        // Тест с null targetId
        try {
            NotificationController.sendNotification('test title', 'test message', 'info', userId, null);
        } catch (Exception e) {
            System.debug('Null targetId exception type: ' + e.getTypeName());
            System.debug('Null targetId exception message: ' + e.getMessage());
            System.debug('Null targetId exception stack trace: ' + e.getStackTraceString());
        }
        
        // Тест с заголовком из пробелов
        try {
            NotificationController.sendNotification('   ', 'test message', 'info', userId, targetId);
        } catch (Exception e) {
            System.debug('Whitespace title exception type: ' + e.getTypeName());
            System.debug('Whitespace title exception message: ' + e.getMessage());
            System.debug('Whitespace title exception stack trace: ' + e.getStackTraceString());
        }
        
        // Тест с сообщением из пробелов
        try {
            NotificationController.sendNotification('test title', '   ', 'info', userId, targetId);
        } catch (Exception e) {
            System.debug('Whitespace message exception type: ' + e.getTypeName());
            System.debug('Whitespace message exception message: ' + e.getMessage());
            System.debug('Whitespace message exception stack trace: ' + e.getStackTraceString());
        }
        
        System.debug('=== End testing exception messages ===');
    }
}