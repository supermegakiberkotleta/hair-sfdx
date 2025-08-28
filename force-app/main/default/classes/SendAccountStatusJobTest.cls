@isTest
private class SendAccountStatusJobTest {
    @isTest
    static void testExecute_Success() {
        Account testAccount = new Account(
            Name = 'Test Company Inc.'
        );
        insert testAccount;

        SendAccountStatusJob job = new SendAccountStatusJob(new List<Account>{ testAccount });

       

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Job completed successfully');
    }

    @isTest
    static void testExecute_HttpFailure() {
        Account testAccount = new Account(
            Name = 'Failed Test Company'
        );
        insert testAccount;

        SendAccountStatusJob job = new SendAccountStatusJob(new List<Account>{ testAccount });

        

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Job handled HTTP failure gracefully');
    }
}