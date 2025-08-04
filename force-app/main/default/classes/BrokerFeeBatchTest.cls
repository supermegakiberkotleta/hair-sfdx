@isTest
private class BrokerFeeBatchTest {
    @isTest
    static void testBatchManualExecution() {
        // Подготовка тестовых данных
        List<Lead> testRecords = new List<Lead>();
        for (Integer i = 0; i < 2; i++) {
            testRecords.add(new Lead(
                LastName = 'Test',
                Company = 'Test',
                Tag__c = 'Denied',
                OfferAmount__c = 1000
            ));
        }
        insert testRecords;

        // Создание батча
        BrokerFeeBatch batch = new BrokerFeeBatch('Lead');

        // Вызов start() вручную
        Database.QueryLocator locator = batch.start(null);
        List<SObject> scope = [SELECT Id, Tag__c, OfferAmount__c, BrokersFee__c FROM Lead];

        // Вызов execute() вручную
        batch.execute(null, scope);

        // Вызов finish() вручную
        batch.finish(null);

        // Проверка обновлений
        List<Lead> updated = [
            SELECT BrokersFee__c FROM Lead
        ];
        for (Lead rec : updated) {
            System.assertNotEquals(null, rec.BrokersFee__c, 'BrokersFee__c должен быть заполнен');
        }
    }
}