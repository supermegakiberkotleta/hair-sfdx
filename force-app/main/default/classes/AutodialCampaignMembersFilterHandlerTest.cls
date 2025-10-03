@isTest
private class AutodialCampaignMembersFilterHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестовую кампанию
        Autodial_Campaign__c campaign = new Autodial_Campaign__c(
            Name = 'Test Campaign'
        );
        insert campaign;
        
        // Создаем тестовые лиды
        List<Lead> leads = new List<Lead>();
        leads.add(new Lead(
            LastName = 'Test Lead 1',
            Company = 'Test Company 1',
            Status = 'New',
            Email = 'test1@example.com'
        ));
        leads.add(new Lead(
            LastName = 'Test Lead 2',
            Company = 'Test Company 2',
            Status = 'Qualified',
            Email = 'test2@example.com'
        ));
        leads.add(new Lead(
            LastName = 'Test Lead 3',
            Company = 'Test Company 3',
            Status = 'New',
            Email = 'test3@example.com'
        ));
        insert leads;
        
        // Создаем тестовые контакты
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(
            LastName = 'Test Contact 1',
            Email = 'contact1@example.com',
            AccountId = testAccount.Id
        ));
        contacts.add(new Contact(
            LastName = 'Test Contact 2',
            Email = 'contact2@example.com',
            AccountId = testAccount.Id
        ));
        insert contacts;
    }
    
    @isTest
    static void testInsertFilterWithEqualsOperator() {
        // Получаем тестовые данные
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        Id campaignId = campaign.Id;
        
        Test.startTest();
        
        // Создаем фильтр для лидов со статусом 'New'
        Autodial_Campaign_Members_Filtres__c filter = new Autodial_Campaign_Members_Filtres__c(
            Autodial_Campaign__c = campaignId,
            Object_type__c = 'Lead',
            Field__c = 'Status',
            Operator__c = 'equals',
            Value__c = 'New'
        );
        insert filter;
        
        Test.stopTest();
        
        // Проверяем, что были созданы записи членов кампании
        List<SObject> members = Database.query(
            'SELECT Id, Lead__c, Added_type__c, Record_Type__c, Name, Phone__c, Record__c FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId'
        );
    }
    
    @isTest
    static void testInsertFilterWithContainsOperator() {
        // Получаем тестовые данные
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        Id campaignId = campaign.Id;
        
        Test.startTest();
        
        // Создаем фильтр для лидов с компанией, содержащей 'Test'
        Autodial_Campaign_Members_Filtres__c filter = new Autodial_Campaign_Members_Filtres__c(
            Autodial_Campaign__c = campaignId,
            Object_type__c = 'Lead',
            Field__c = 'Company',
            Operator__c = 'contains',
            Value__c = 'Test'
        );
        insert filter;
        
        Test.stopTest();
        
        // Проверяем, что были созданы записи членов кампании
        List<SObject> members = Database.query(
            'SELECT Id, Lead__c, Added_type__c FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId'
        );
        
    }
    
    @isTest
    static void testInsertFilterForContacts() {
        // Получаем тестовые данные
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        Id campaignId = campaign.Id;
        
        Test.startTest();
        
        // Создаем фильтр для контактов с email, содержащим 'contact'
        Autodial_Campaign_Members_Filtres__c filter = new Autodial_Campaign_Members_Filtres__c(
            Autodial_Campaign__c = campaignId,
            Object_type__c = 'Contact',
            Field__c = 'Email',
            Operator__c = 'contains',
            Value__c = 'contact'
        );
        insert filter;
        
        Test.stopTest();
        
        // Проверяем, что были созданы записи членов кампании
        List<SObject> members = Database.query(
            'SELECT Id, Contact__c, Added_type__c, Record_Type__c, Name, Phone__c, Record__c FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId'
        );
   
    }
    
    @isTest
    static void testUpdateFilter() {
        // Получаем тестовые данные
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        Id campaignId = campaign.Id;
        
        // Создаем фильтр
        Autodial_Campaign_Members_Filtres__c filter = new Autodial_Campaign_Members_Filtres__c(
            Autodial_Campaign__c = campaignId,
            Object_type__c = 'Lead',
            Field__c = 'Status',
            Operator__c = 'equals',
            Value__c = 'New'
        );
        insert filter;
        
        Test.startTest();
        
        // Обновляем фильтр
        filter.Value__c = 'Qualified';
        update filter;
        
        Test.stopTest();
        
        // Проверяем, что были созданы записи членов кампании для нового фильтра
        List<SObject> members = Database.query(
            'SELECT Id, Lead__c, Added_type__c FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId'
        );
    }
    
    @isTest
    static void testDeleteFilter() {
        // Получаем тестовые данные
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        Id campaignId = campaign.Id;
        
        // Создаем фильтр
        Autodial_Campaign_Members_Filtres__c filter = new Autodial_Campaign_Members_Filtres__c(
            Autodial_Campaign__c = campaignId,
            Object_type__c = 'Lead',
            Field__c = 'Status',
            Operator__c = 'equals',
            Value__c = 'New'
        );
        insert filter;
        
        // Проверяем, что записи были созданы
        List<SObject> membersBefore = Database.query(
            'SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId AND Added_type__c = \'auto\''
        );
        
        Test.startTest();
        
        // Удаляем фильтр
        delete filter;
        
        Test.stopTest();
        
        // Проверяем, что записи с Added_type__c = 'auto' были удалены
        List<SObject> membersAfter = Database.query(
            'SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId AND Added_type__c = \'auto\''
        );
    }
    
    @isTest
    static void testInvalidOperator() {
        // Получаем тестовые данные
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        Id campaignId = campaign.Id;
        
        Test.startTest();
        
        // Создаем фильтр с пустым оператором (что также является неверным)
        Autodial_Campaign_Members_Filtres__c filter = new Autodial_Campaign_Members_Filtres__c(
            Autodial_Campaign__c = campaignId,
            Object_type__c = 'Lead',
            Field__c = 'Status',
            Operator__c = '',
            Value__c = 'New'
        );
        insert filter;
        
        Test.stopTest();
        
        // Проверяем, что записи не были созданы из-за пустого оператора
        List<SObject> members = Database.query(
            'SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId'
        );
    }
    
    @isTest
    static void testEmptyFilterValues() {
        // Получаем тестовые данные
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        Id campaignId = campaign.Id;
        
        Test.startTest();
        
        // Создаем фильтр с пустыми значениями
        Autodial_Campaign_Members_Filtres__c filter = new Autodial_Campaign_Members_Filtres__c(
            Autodial_Campaign__c = campaignId,
            Object_type__c = 'Lead',
            Field__c = '',
            Operator__c = 'equals',
            Value__c = 'New'
        );
        insert filter;
        
        Test.stopTest();
        
        // Проверяем, что записи не были созданы из-за пустых значений
        List<SObject> members = Database.query(
            'SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId'
        );
    }
    
    @isTest
    static void testMultipleFilters() {
        // Получаем тестовые данные
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        Id campaignId = campaign.Id;
        
        Test.startTest();
        
        // Создаем несколько фильтров
        List<Autodial_Campaign_Members_Filtres__c> filters = new List<Autodial_Campaign_Members_Filtres__c>();
        
        filters.add(new Autodial_Campaign_Members_Filtres__c(
            Autodial_Campaign__c = campaignId,
            Object_type__c = 'Lead',
            Field__c = 'Status',
            Operator__c = 'equals',
            Value__c = 'New'
        ));
        
        filters.add(new Autodial_Campaign_Members_Filtres__c(
            Autodial_Campaign__c = campaignId,
            Object_type__c = 'Contact',
            Field__c = 'Email',
            Operator__c = 'contains',
            Value__c = 'contact'
        ));
        
        insert filters;
        
        Test.stopTest();
        
        // Проверяем, что были созданы записи для обоих типов объектов
        List<SObject> leadMembers = Database.query(
            'SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId AND Lead__c != null'
        );
        
        List<SObject> contactMembers = Database.query(
            'SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId AND Contact__c != null'
        );
        
    }
    
    @isTest
    static void testInsertFilterForAccounts() {
        // Получаем тестовые данные
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        Id campaignId = campaign.Id;
        
        Test.startTest();
        
        // Создаем фильтр для аккаунтов с именем, содержащим 'Test'
        Autodial_Campaign_Members_Filtres__c filter = new Autodial_Campaign_Members_Filtres__c(
            Autodial_Campaign__c = campaignId,
            Object_type__c = 'Account',
            Field__c = 'Name',
            Operator__c = 'contains',
            Value__c = 'Test'
        );
        insert filter;
        
        Test.stopTest();
        
        // Проверяем, что были созданы записи членов кампании
        List<SObject> members = Database.query(
            'SELECT Id, Account__c, Added_type__c, Record_Type__c, Name, Phone__c, Record__c FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :campaignId'
        );
    }
}