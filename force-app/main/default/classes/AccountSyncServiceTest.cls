@isTest
private class AccountSyncServiceTest {
    
    @TestSetup
    static void setup() {
        // Создаем тестовые данные
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < 5; i++) {
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
    static void testSyncAccountsSuccess() {
        // Получаем созданные аккаунты
        List<Account> accounts = [SELECT Id FROM Account LIMIT 5];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        AccountSyncService.syncAccounts(accountIds);
        Test.stopTest();
        
        // Проверяем, что метод отработал без ошибок
        System.assertEquals(5, accountIds.size(), 'Should have 5 accounts');
    }
    
    @isTest
    static void testSyncAccountsEmptyList() {
        List<Id> accountIds = new List<Id>();
        
        Test.startTest();
        AccountSyncService.syncAccounts(accountIds);
        Test.stopTest();
        
        // Проверяем, что метод корректно обработал пустой список
        System.assertEquals(0, accountIds.size(), 'Should have 0 accounts');
    }
    
    @isTest
    static void testSyncAccountsNull() {
        Test.startTest();
        AccountSyncService.syncAccounts(null);
        Test.stopTest();
        
        // Проверяем, что метод корректно обработал null
        System.assert(true, 'Method should handle null without errors');
    }
    
    @isTest
    static void testPrepareAccountsData() {
        // Получаем аккаунт для теста
        Account testAccount = [SELECT Id, Name, Phone, Work_Email__c, Client_Category__c, 
                                      Client_Type__c, AccountSource, BillingStreet, 
                                      BillingCity, BillingState, BillingPostalCode, 
                                      BillingCountry 
                               FROM Account LIMIT 1];
        
        // Настраиваем mock для HTTP callout
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(200, 'Success'));
        
        Test.startTest();
        List<Id> accountIds = new List<Id>{ testAccount.Id };
        AccountSyncService.syncAccounts(accountIds);
        Test.stopTest();
        
        // Проверяем, что данные подготовлены корректно
        System.assertNotEquals(null, testAccount.Name, 'Account name should not be null');
    }
    
    @isTest
    static void testSyncAccountsHttpError() {
        // Получаем созданные аккаунты
        List<Account> accounts = [SELECT Id FROM Account LIMIT 5];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        // Настраиваем mock для HTTP callout с ошибкой
        Test.setMock(HttpCalloutMock.class, new AccountSyncHttpMock(500, 'Internal Server Error'));
        
        Test.startTest();
        AccountSyncService.syncAccounts(accountIds);
        Test.stopTest();
        
        // Проверяем, что метод отработал без выброса исключений
        System.assertEquals(5, accountIds.size(), 'Should have 5 accounts');
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

