@isTest
private class LeadQueueAssignmentTriggerTest {

    @isTest
    static void testLeadQueueAssignmentTrigger() {
        // Подготовка данных (если assignOwners зависит от каких-либо данных, добавьте их здесь)

        // Создаем лида
        Lead testLead = new Lead(
            LastName = 'Test',
            Company = 'Test Company',
            Status = 'New',
            RecordTypeId = '012Kc000000ten6IAA'
        );

        // Вставляем лида — это вызовет триггер
        Test.startTest();
        insert testLead;
        Test.stopTest();

        // Проверка — если assignOwners меняет OwnerId или другие поля, проверьте это
        Lead insertedLead = [SELECT Id, OwnerId FROM Lead WHERE Id = :testLead.Id];

        // Пример проверки (зависит от логики assignOwners)
        System.assertNotEquals(null, insertedLead.OwnerId, 'OwnerId должен быть установлен assignOwners');
    }
}