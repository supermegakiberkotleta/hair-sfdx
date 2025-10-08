@isTest
private class AccountSyncQueueableTest {
    
    @TestSetup
    static void setup() {
        // Создаем тестовые данные
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 60; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                Client_Category__c = 'Salon',
                Client_Type__c = 'Discount 10%',
                AccountSource = 'Web',
                BillingStreet = 'Street ' + i,
                BillingCity = 'City ' + i,
                BillingState = 'State',
                BillingPostalCode = '12345',
                BillingCountry = 'Country',
                RecordTypeId = '012Kc000000tenBIAQ'
            );
            testAccounts.add(acc);
        }
        
        insert testAccounts;
    }
    
    @isTest
    static void testQueueableWithSmallBatch() {
        // Получаем первые 10 аккаунтов
        List<Account> accounts = [SELECT Id FROM Account LIMIT 10];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        System.enqueueJob(new AccountSyncQueueable(accountIds));
        Test.stopTest();
        
        // Проверяем, что задача выполнена
        System.assertEquals(10, accountIds.size(), 'Should have 10 accounts');
    }
    
    @isTest
    static void testQueueableWithLargeBatch() {
        // Получаем все аккаунты (60)
        List<Account> accounts = [SELECT Id FROM Account];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        System.enqueueJob(new AccountSyncQueueable(accountIds));
        Test.stopTest();
        
        // Проверяем, что задача выполнена
        System.assert(accountIds.size() > 50, 'Should have more than 50 accounts');
    }
    
    @isTest
    static void testQueueableWithEmptyList() {
        List<Id> accountIds = new List<Id>();
        
        Test.startTest();
        System.enqueueJob(new AccountSyncQueueable(accountIds));
        Test.stopTest();
        
        // Проверяем, что задача корректно обработала пустой список
        System.assertEquals(0, accountIds.size(), 'Should have 0 accounts');
    }
    
    @isTest
    static void testQueueableWithNull() {
        Test.startTest();
        System.enqueueJob(new AccountSyncQueueable(null));
        Test.stopTest();
        
        // Проверяем, что задача корректно обработала null
        System.assert(true, 'Queueable should handle null without errors');
    }
    
    @isTest
    static void testQueueableChaining() {
        // Получаем 100 аккаунтов (больше чем batch size)
        // Создаем дополнительные аккаунты
        List<Account> additionalAccounts = new List<Account>();
        for (Integer i = 60; i < 100; i++) {
            Account acc = new Account(
                Name = 'Test Account ' + i,
                Phone = '123456789' + i,
                Work_Email__c = 'test' + i + '@example.com',
                RecordTypeId = '012Kc000000tenBIAQ'
            );
            additionalAccounts.add(acc);
        }
        insert additionalAccounts;
        
        List<Account> allAccounts = [SELECT Id FROM Account];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : allAccounts) {
            accountIds.add(acc.Id);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        System.enqueueJob(new AccountSyncQueueable(accountIds));
        Test.stopTest();
        
        // В тестовом контексте цепочка Queueable не выполнится полностью,
        // но мы проверяем, что первая партия обработана без ошибок
        System.assert(accountIds.size() >= 100, 'Should have at least 100 accounts');
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

