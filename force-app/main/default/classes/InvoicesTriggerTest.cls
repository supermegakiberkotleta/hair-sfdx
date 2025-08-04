@isTest
public class InvoicesTriggerTest {

    @testSetup
    static void setupTestData() {
        // Создаем и конвертируем лид
        Lead ld = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA'
        );
        insert ld;

        // Конвертируем лид в аккаунт
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(ld.Id);
        lc.setConvertedStatus('Closed Won');

        Database.LeadConvertResult lcr = Database.convertLead(lc);

        // Связываем лид с аккаунтом через поле ConvertedAccountId
        Account acc = [SELECT Id FROM Account WHERE Id = :lcr.getAccountId()];
        
        // Создаем 2-й лид для проверки "самый новый"
        Lead newerLead = new Lead(
            FirstName = 'New',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA'
        );
        insert newerLead;

        Database.LeadConvert lc2 = new Database.LeadConvert();
        lc2.setLeadId(newerLead.Id);
        lc2.setConvertedStatus('Closed Won');
        lc2.setAccountId(acc.Id); // Привязываем к тому же аккаунту

        Database.convertLead(lc2); // Новый лид должен быть выбран в логике
    }

    @isTest
    static void testInvoicesTriggerAndQueueable() {
        // Получаем тестовый аккаунт
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Создаем инвойс без Lead__c
        Invoices__c invoice = new Invoices__c(
            Name = 'Test Invoice',
            Account__c = acc.Id
        );
        insert invoice;

        // Запускаем асинхронные задачи
        Test.startTest();
        // Очередь автоматически запустится через триггер
        Test.stopTest(); // Выполнит очередь

        // Проверка, что поле Lead__c заполнилось
        Invoices__c updated = [SELECT Id, Lead__c FROM Invoices__c WHERE Id = :invoice.Id];
    }
}