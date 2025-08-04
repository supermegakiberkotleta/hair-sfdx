@isTest
private class UpdateLeadTagsTest {
    
    static final String RECORD_TYPE_ID = '012Kc000000tenuIAA'; // Убедись, что это актуальный Id в тесте, иначе можно получить его программно.

    @isTest
    static void testTagCreationAndUpdate() {
        // Step 1: Создание лида с Tag__c = 'Biz Capital 10%'
        Lead testLead = new Lead(
            LastName = 'Test Lead',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = RECORD_TYPE_ID,
            Tag__c = 'Biz Capital 10%',
            Broker_email__c = 'broker@example.com'
        );
        insert testLead;

        // Проверка: должна быть создана запись Tag__c с флагом biz_capital_10__c = true
        Tag__c createdTag = [SELECT Id, biz_capital_10__c, Lead__c FROM Tag__c WHERE Lead__c = :testLead.Id LIMIT 1];
        System.assertNotEquals(null, createdTag);
        System.assertEquals(true, createdTag.biz_capital_10__c);

        // Step 2: Обновление лида — меняем Tag__c
        testLead.Tag__c = 'Denied';
        update testLead;

        // Проверка: должна быть создана новая запись Tag__c с флагом denied__c = true, а старая удалена
        List<Tag__c> tags = [SELECT Id, denied__c, biz_capital_10__c FROM Tag__c WHERE Lead__c = :testLead.Id];
        System.assertEquals(1, tags.size());
        System.assertEquals(true, tags[0].denied__c);
        System.assertEquals(false, tags[0].biz_capital_10__c); // Или null, если unset
    }

    @isTest
    static void testIgnoredRecordType() {
        // Lead с другим RecordTypeId — триггер не должен отработать
        Lead lead = new Lead(
            LastName = 'Wrong Type',
            Company = 'Some Company',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA', // НЕ тот ID
            Tag__c = 'Denied',
            Broker_email__c = 'test@wrong.com'
        );
        insert lead;

        List<Tag__c> tags = [SELECT Id FROM Tag__c WHERE Lead__c = :lead.Id];
        System.assertEquals(0, tags.size(), 'Триггер не должен был создать запись Tag__c');
    }
}