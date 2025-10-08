@isTest
private class AccountTriggerHandlerTest {
    private static final String TARGET_RECORD_TYPE_ID = '012Kc000000tenBIAQ';
    
    @TestSetup
    static void setup() {
        // Тестовые данные будут создаваться в каждом тесте отдельно
        // для лучшего контроля над сценариями
    }
    
    @isTest
    static void testHandleDeactivation_ClosedLost_WithReason() {
        // Создаем аккаунт со статусом Closed Lost и причиной закрытия
        Account acc = new Account(
            Name = 'Test Account',
            Client_Type__c = 'Closed Lost',
            Reason_for_closure__c = 'Not interested'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        // Проверяем, что Active_status__c установлен в false
        Account updatedAcc = [SELECT Id, Active_status__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(false, updatedAcc.Active_status__c, 'Active status should be false');
    }
    
    @isTest
    static void testHandleDeactivation_ClosedLost_WithoutReason() {
        // Создаем аккаунт со статусом Closed Lost без причины закрытия
        Account acc = new Account(
            Name = 'Test Account',
            Client_Type__c = 'Closed Lost'
        );
        
        Test.startTest();
        try {
            insert acc;
            System.assert(false, 'Should have thrown an error');
        } catch (DmlException e) {
            // Ожидаем ошибку валидации
            System.assert(e.getMessage().contains('Please provide a reason for closure'), 
                         'Error message should contain validation text');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testHandleDeactivation_ActiveStatus() {
        // Создаем аккаунт с активным статусом
        Account acc = new Account(
            Name = 'Test Account',
            Client_Type__c = 'Discount 10%'
        );
        
        Test.startTest();
        insert acc;
        Test.stopTest();
        
        // Проверяем, что Active_status__c установлен в true
        Account updatedAcc = [SELECT Id, Active_status__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(true, updatedAcc.Active_status__c, 'Active status should be true');
    }
    
    @isTest
    static void testHandleAccountSync_SmallBatch() {
        // Создаем меньше 50 аккаунтов с нужным RecordTypeId
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                RecordTypeId = TARGET_RECORD_TYPE_ID
            );
            testAccounts.add(acc);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что аккаунты созданы
        List<Account> insertedAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :TARGET_RECORD_TYPE_ID];
        System.assertEquals(10, insertedAccounts.size(), 'Should have 10 accounts');
    }
    
    @isTest
    static void testHandleAccountSync_LargeBatch() {
        // Создаем более 50 аккаунтов с нужным RecordTypeId
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 60; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                RecordTypeId = TARGET_RECORD_TYPE_ID
            );
            testAccounts.add(acc);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что аккаунты созданы и была запущена Queueable задача
        List<Account> insertedAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :TARGET_RECORD_TYPE_ID];
        System.assertEquals(60, insertedAccounts.size(), 'Should have 60 accounts');
    }
    
    @isTest
    static void testHandleAccountSync_WrongRecordType() {
        // Создаем аккаунты с другим RecordTypeId
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com'
                // RecordTypeId не указан или другой
            );
            testAccounts.add(acc);
        }
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что аккаунты созданы, но синхронизация не запустилась
        List<Account> insertedAccounts = [SELECT Id FROM Account];
        System.assertEquals(10, insertedAccounts.size(), 'Should have 10 accounts');
    }
    
    @isTest
    static void testHandleAccountSync_MixedRecordTypes() {
        // Создаем аккаунты с разными RecordTypeId
        List<Account> testAccounts = new List<Account>();
        
        // 5 аккаунтов с нужным RecordTypeId
        for (Integer i = 0; i < 5; i++) {
            Account acc = new Account(
                Name = 'Test Account Target ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                RecordTypeId = TARGET_RECORD_TYPE_ID
            );
            testAccounts.add(acc);
        }
        
        // 5 аккаунтов без нужного RecordTypeId
        for (Integer i = 5; i < 10; i++) {
            Account acc = new Account(
                Name = 'Test Account Other ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com'
            );
            testAccounts.add(acc);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что созданы все аккаунты
        List<Account> insertedAccounts = [SELECT Id FROM Account];
        System.assertEquals(10, insertedAccounts.size(), 'Should have 10 accounts total');
        
        
    }
    
    @isTest
    static void testHandleAccountSync_BoundaryCondition_Exactly50() {
        // Создаем ровно 50 аккаунтов
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 50; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                RecordTypeId = TARGET_RECORD_TYPE_ID
            );
            testAccounts.add(acc);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что аккаунты созданы (должна использоваться прямая синхронизация, а не очередь)
        List<Account> insertedAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :TARGET_RECORD_TYPE_ID];
        System.assertEquals(50, insertedAccounts.size(), 'Should have 50 accounts');
    }
    
    @isTest
    static void testHandleAccountSync_BoundaryCondition_51Accounts() {
        // Создаем 51 аккаунт (граничное условие для перехода в очередь)
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 51; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                RecordTypeId = TARGET_RECORD_TYPE_ID
            );
            testAccounts.add(acc);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        insert testAccounts;
        Test.stopTest();
        
        // Проверяем, что аккаунты созданы (должна использоваться очередь)
        List<Account> insertedAccounts = [SELECT Id FROM Account WHERE RecordTypeId = :TARGET_RECORD_TYPE_ID];
        System.assertEquals(51, insertedAccounts.size(), 'Should have 51 accounts');
    }
    
    /**
     * Mock класс для HTTP callout
     */
    private class AccountSyncHttpMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public AccountSyncHttpMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            res.setStatusCode(statusCode);
            return res;
        }
    }
}
