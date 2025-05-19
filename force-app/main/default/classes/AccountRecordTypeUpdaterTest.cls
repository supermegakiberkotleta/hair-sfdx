@isTest
public class AccountRecordTypeUpdaterTest {
    
    @isTest static void testBatchExecution() {
        // Создаем тестовые данные
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 300; i++) {
            accounts.add(new Account(
                Name = 'Test' + i,
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfos()[0].getRecordTypeId()
            ));
        }
        insert accounts;
        
        // Устанавливаем значения RecordTypeIdFilter__c в null
        for (Account l : [SELECT Id, RecordTypeIdFilter__c FROM Account]) {
            l.RecordTypeIdFilter__c = null;
        }
        update accounts;

        // Запуск батч-процесса
        Test.startTest();
        AccountRecordTypeUpdater batch = new AccountRecordTypeUpdater();
        Database.executeBatch(batch, 100);
        Test.stopTest();

        // Проверка обновления записей
        List<Account> updatedAccounts = [SELECT RecordTypeId, RecordTypeIdFilter__c FROM Account];
        for (Account l : updatedAccounts) {
            System.assertEquals(l.RecordTypeId, l.RecordTypeIdFilter__c, 
                'RecordTypeIdFilter__c должно совпадать с RecordTypeId');
        }
        
        System.assertEquals(300, updatedAccounts.size(), 
            'Должны быть обновлены все 300 записей');
    }
}
