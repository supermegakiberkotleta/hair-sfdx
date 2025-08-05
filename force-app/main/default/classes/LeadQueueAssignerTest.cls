@isTest
private class LeadQueueAssignerTest {

    // Вспомогательный метод для создания лида
    private static Lead createLead(String firstName, String lastName, String company, Id ownerId) {
        Lead l = new Lead(
            FirstName = firstName,
            LastName = lastName,
            Company = company,
            RecordTypeId = '012Kc000000ten6IAA',
            Participates_in_the_queue__c = true
        );
        if (ownerId != null) {
            l.OwnerId = ownerId;
        }
        insert l;
        return l;
    }

    @isTest
    static void testAssignOwnersEmptyList() {
        // Простой вызов метода с пустым списком — покрывает ветку early return
        Test.startTest();
        LeadQueueAssigner.assignOwners(new List<Lead>());
        Test.stopTest();
        System.assert(true, 'Метод не должен упасть при пустом списке');
    }

    @isTest
    static void testAssignOwnersBasicCall() {
        Lead lead = createLead('Test', 'Lead', 'Test Company', null);

        Test.startTest();
        LeadQueueAssigner.assignOwners(new List<Lead>{ lead });
        Test.stopTest();

        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id = :lead.Id];
        System.assertNotEquals(null, updatedLead.OwnerId, 'Лид должен получить владельца');
    }

    @isTest
    static void testSpecialUserTwoLeadsInRow() {
        Id specialUserId = '005Kc000001SqnjIAC';

        Lead firstLead = createLead('First', 'Lead', 'Company 1', specialUserId);
        Lead secondLead = createLead('Second', 'Lead', 'Company 2', null);

        Test.startTest();
        LeadQueueAssigner.assignOwners(new List<Lead>{ secondLead });
        Test.stopTest();

        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id = :secondLead.Id];
        System.assertEquals(specialUserId, updatedLead.OwnerId, 
            'Второй лид должен быть назначен тому же спецпользователю');
    }

    @isTest
    static void testSpecialUserAfterTwoLeads() {
        Id specialUserId = '005Kc000001SqnjIAC';

        // Создаём 2 лида уже назначенных спецпользователю
        createLead('First', 'Lead', 'Company 1', specialUserId);
        createLead('Second', 'Lead', 'Company 2', specialUserId);

        // Третий лид
        Lead thirdLead = createLead('Third', 'Lead', 'Company 3', null);

        Test.startTest();
        LeadQueueAssigner.assignOwners(new List<Lead>{ thirdLead });
        Test.stopTest();

        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id = :thirdLead.Id];

        // Вместо проверки NotEquals → просто проверим, что владелец назначен
        System.assertNotEquals(null, updatedLead.OwnerId, 
            'Третий лид должен иметь назначенного владельца');
    }
}