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
        );
        insert lead;

        // Вызов метода с одним лидом
        LeadQueueAssigner.assignOwners(new List<Lead>{ lead });
    }

    @isTest
    static void testSpecialUserTwoLeadsInRow() {
        // Создаём первого лида для специального пользователя
        Lead firstLead = new Lead(
            FirstName = 'First',
            LastName = 'Lead',
            Company = 'Test Company 1',
            RecordTypeId = '012Kc000000ten6IAA',
            Participates_in_the_queue__c = true,
            OwnerId = '005Kc000001SqnjIAC'
        );
        insert firstLead;

        // Создаём второго лида и вставляем его в базу
        Lead secondLead = new Lead(
            FirstName = 'Second',
            LastName = 'Lead',
            Company = 'Test Company 2',
            RecordTypeId = '012Kc000000ten6IAA',
            Participates_in_the_queue__c = true
        );
        insert secondLead;

        // Получаем лид из базы данных для обработки
        Lead leadToProcess = [SELECT Id, OwnerId, RecordTypeId, Participates_in_the_queue__c 
                             FROM Lead WHERE Id = :secondLead.Id];

        // Вызываем метод назначения
        LeadQueueAssigner.assignOwners(new List<Lead>{ leadToProcess });

        // Проверяем, что второй лид назначен тому же пользователю
        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id = :secondLead.Id];
        System.assertEquals('005Kc000001SqnjIAC', updatedLead.OwnerId, 
            'Second lead should be assigned to the same special user');
    }

    @isTest
    static void testSpecialUserAfterTwoLeads() {
        // Создаём двух лидов для специального пользователя
        Lead firstLead = new Lead(
            FirstName = 'First',
            LastName = 'Lead',
            Company = 'Test Company 1',
            RecordTypeId = '012Kc000000ten6IAA',
            Participates_in_the_queue__c = true,
            OwnerId = '005Kc000001SqnjIAC'
        );
        insert firstLead;

        Lead secondLead = new Lead(
            FirstName = 'Second',
            LastName = 'Lead',
            Company = 'Test Company 2',
            RecordTypeId = '012Kc000000ten6IAA',
            Participates_in_the_queue__c = true,
            OwnerId = '005Kc000001SqnjIAC'
        );
        insert secondLead;

        // Создаём третьего лида и вставляем его в базу
        Lead thirdLead = new Lead(
            FirstName = 'Third',
            LastName = 'Lead',
            Company = 'Test Company 3',
            RecordTypeId = '012Kc000000ten6IAA',
            Participates_in_the_queue__c = true
        );
        insert thirdLead;

        // Получаем лид из базы данных для обработки
        Lead leadToProcess = [SELECT Id, OwnerId, RecordTypeId, Participates_in_the_queue__c 
                             FROM Lead WHERE Id = :thirdLead.Id];

        // Вызываем метод назначения
        LeadQueueAssigner.assignOwners(new List<Lead>{ leadToProcess });

        // Проверяем, что третий лид назначен другому пользователю
        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id = :thirdLead.Id];
        System.assertNotEquals('005Kc000001SqnjIAC', updatedLead.OwnerId, 
            'Third lead should be assigned to a different user after special user had 2 leads');
    }
}
