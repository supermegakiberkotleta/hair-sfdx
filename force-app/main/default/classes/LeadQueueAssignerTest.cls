@isTest
private class LeadQueueAssignerTest {

    @isTest
    static void testAssignOwnersEmptyList() {
        // Простой вызов метода с пустым списком — покрывает ветку early return
        LeadQueueAssigner.assignOwners(new List<Lead>());
    }

    @isTest
    static void testAssignOwnersBasicCall() {
        // Создаём лида с нужным RecordTypeId и пустым OwnerId
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            RecordTypeId = '012Kc000000ten6IAA',
            Participates_in_the_queue__c = true
           // OwnerId = '005Kc000001SjYMIA0'
        );
        insert lead;

        // Вызов метода с одним лидом
        LeadQueueAssigner.assignOwners(new List<Lead>{ lead });
    }
}
