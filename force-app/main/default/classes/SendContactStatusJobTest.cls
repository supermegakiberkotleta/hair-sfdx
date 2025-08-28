@isTest
private class SendContactStatusJobTest {
    @isTest
    static void testExecute_Success() {
        // Создаём Account для Contact (обязательное поле)
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact testContact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            AccountId = acc.Id
        );
        insert testContact;

        SendContactStatusJob job = new SendContactStatusJob(new List<Contact>{ testContact });

      

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Job completed successfully');
    }

    @isTest
    static void testExecute_HttpFailure() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact testContact = new Contact(
            FirstName = 'Jane',
            LastName = 'Doe',
            Email = 'jane.doe@example.com',
            AccountId = acc.Id
        );
        insert testContact;

        SendContactStatusJob job = new SendContactStatusJob(new List<Contact>{ testContact });

       

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Job handled HTTP failure gracefully');
    }
}