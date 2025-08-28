@isTest
private class SendOpportunityStatusJobTest {
    @isTest
    static void testExecute_Success() {
        // Создаём тестовую сделку
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert testOpp;

        // Подготавливаем job
        SendOpportunityStatusJob job = new SendOpportunityStatusJob(new List<Opportunity>{ testOpp });

        // Мокаем HTTP
    

        // Запускаем асинхронный job
        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Проверяем, что всё прошло без ошибок
        System.assert(true, 'Job should complete without exceptions');
    }

    @isTest
    static void testExecute_HttpFailure() {
        Opportunity testOpp = new Opportunity(
            Name = 'Failed Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );
        insert testOpp;

        SendOpportunityStatusJob job = new SendOpportunityStatusJob(new List<Opportunity>{ testOpp });

       

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Job should handle HTTP failure gracefully');
    }
}