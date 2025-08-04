@isTest
public class LeadRecordTypeUpdaterTest {
    
    @isTest static void testBatchExecution() {
        // Создаем тестовые данные
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 300; i++) {
            leads.add(new Lead(
                FirstName = 'Test' + i,
                LastName = 'Lead' + i,
                Company = 'TestCompany' + i,
                RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfos()[0].getRecordTypeId()
            ));
        }
        insert leads;
        
        // Устанавливаем значения RecordTypeIdFilter__c в null
        for (Lead l : [SELECT Id, RecordTypeIdFilter__c FROM Lead]) {
            l.RecordTypeIdFilter__c = null;
        }
        update leads;

        // Запуск батч-процесса
        Test.startTest();
        LeadRecordTypeUpdater batch = new LeadRecordTypeUpdater();
        Database.executeBatch(batch, 100);
        Test.stopTest();

        // Проверка обновления записей
        List<Lead> updatedLeads = [SELECT RecordTypeId, RecordTypeIdFilter__c FROM Lead];
        for (Lead l : updatedLeads) {
            System.assertEquals(l.RecordTypeId, l.RecordTypeIdFilter__c, 
                'RecordTypeIdFilter__c должно совпадать с RecordTypeId');
        }
        
        System.assertEquals(300, updatedLeads.size(), 
            'Должны быть обновлены все 300 записей');
    }
}