@isTest
private class DeleteRecordsByRecordTypeBatchTest {

    // Задаем тестовые RecordTypeId как константы (аналогично реальным ID)
    static final String LEAD_RT = '012Kc000000ten6IAA';
    static final String CONTACT_RT = '012Kc000000tenGIAQ';
    static final String ACCOUNT_RT = '012Kc000000tenBIAQ';
    static final String OPPORTUNITY_RT = '012Kc000000tRXzIAM';

    @isTest
    static void testDeleteLeadsByRecordType() {
        // Создание тестовых Lead'ов
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 5; i++) {
            leads.add(new Lead(LastName = 'TestLead' + i, Company = 'TestCompany', RecordTypeId = LEAD_RT));
        }
        insert leads;

        // Убедимся, что они вставлены
        System.assertEquals(5, [SELECT COUNT() FROM Lead WHERE RecordTypeId = :LEAD_RT]);

        // Запуск Batch
        Test.startTest();
        Database.executeBatch(new DeleteRecordsByRecordTypeBatch('Lead', LEAD_RT), 200);
        Test.stopTest();

        // Проверка, что все удалены
        System.assertEquals(0, [SELECT COUNT() FROM Lead WHERE RecordTypeId = :LEAD_RT]);
    }

    @isTest
    static void testDeleteContactsByRecordType() {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(LastName = 'TestContact' + i, RecordTypeId = CONTACT_RT));
        }
        insert contacts;
        System.assertEquals(5, [SELECT COUNT() FROM Contact WHERE RecordTypeId = :CONTACT_RT]);

        Test.startTest();
        Database.executeBatch(new DeleteRecordsByRecordTypeBatch('Contact', CONTACT_RT), 200);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Contact WHERE RecordTypeId = :CONTACT_RT]);
    }

    @isTest
    static void testDeleteAccountsByRecordType() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'TestAccount' + i, RecordTypeId = ACCOUNT_RT));
        }
        insert accounts;
        System.assertEquals(5, [SELECT COUNT() FROM Account WHERE RecordTypeId = :ACCOUNT_RT]);

        Test.startTest();
        Database.executeBatch(new DeleteRecordsByRecordTypeBatch('Account', ACCOUNT_RT), 200);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE RecordTypeId = :ACCOUNT_RT]);
    }

    @isTest
    static void testDeleteOpportunitiesByRecordType() {
        // Для создания Opportunities нужен Account
        Account acc = new Account(Name = 'ParentAcc');
        insert acc;

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            opportunities.add(new Opportunity(Name = 'TestOpp' + i, StageName = 'Prospecting', CloseDate = Date.today().addDays(10),
                                              AccountId = acc.Id, RecordTypeId = OPPORTUNITY_RT));
        }
        insert opportunities;
        System.assertEquals(5, [SELECT COUNT() FROM Opportunity WHERE RecordTypeId = :OPPORTUNITY_RT]);

        Test.startTest();
        Database.executeBatch(new DeleteRecordsByRecordTypeBatch('Opportunity', OPPORTUNITY_RT), 200);
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM Opportunity WHERE RecordTypeId = :OPPORTUNITY_RT]);
    }
}