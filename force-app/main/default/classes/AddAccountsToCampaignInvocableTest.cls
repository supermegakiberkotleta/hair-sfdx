@IsTest
private class AddAccountsToCampaignInvocableTest {
    
    @IsTest
    static void testAddAccountsToCampaign_Basic() {
        // Создаем тестовые данные
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Campaign testCampaign = new Campaign(
            Name = 'Test Campaign',
            Type = 'Email',
            Status = 'Planned',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(30)
        );
        insert testCampaign;
        
        // Подготавливаем запрос
        AddAccountsToCampaignInvocable.Req request = new AddAccountsToCampaignInvocable.Req();
        request.campaignId = testCampaign.Id;
        request.accountIds = new List<Id>{testAccount.Id};
        request.status = 'Sent';
        
        Test.startTest();
        List<AddAccountsToCampaignInvocable.Result> results = AddAccountsToCampaignInvocable.addAccounts(new List<AddAccountsToCampaignInvocable.Req>{request});
        Test.stopTest();
        
        // Проверяем результат
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].message.contains('added: 1'), 'Should indicate 1 account added');
        
        List<CampaignMember> members = [
            SELECT Id, CampaignId, AccountId, Status 
            FROM CampaignMember 
            WHERE CampaignId = :testCampaign.Id
        ];
        
        System.assertEquals(1, members.size(), 'Should create 1 campaign member');
        System.assertEquals(testAccount.Id, members[0].AccountId, 'Account should match');
    }
    
    @IsTest
    static void testAddAccountsToCampaign_EmptyRequest() {
        Test.startTest();
        List<AddAccountsToCampaignInvocable.Result> results1 = AddAccountsToCampaignInvocable.addAccounts(null);
        List<AddAccountsToCampaignInvocable.Result> results2 = AddAccountsToCampaignInvocable.addAccounts(new List<AddAccountsToCampaignInvocable.Req>());
        Test.stopTest();
        
        // Проверяем результат
        System.assertEquals(1, results1.size(), 'Should return one result for null');
        System.assert(results1[0].message.contains('No requests'), 'Should indicate no requests');
        
        System.assertEquals(1, results2.size(), 'Should return one result for empty list');
        System.assert(results2[0].message.contains('No requests'), 'Should indicate no requests');
        
        // Проверяем, что ничего не создалось
        List<CampaignMember> members = [SELECT Id FROM CampaignMember];
        System.assertEquals(0, members.size(), 'Should not create any members with empty request');
    }
    
    @IsTest
    static void testAddAccountsToCampaign_MultipleAccounts() {
        // Создаем тестовые данные
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert testAccounts;
        
        Campaign testCampaign = new Campaign(
            Name = 'Test Campaign 2',
            Type = 'Email',
            Status = 'Planned',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(30)
        );
        insert testCampaign;
        
        // Подготавливаем запрос с несколькими аккаунтами
        AddAccountsToCampaignInvocable.Req request = new AddAccountsToCampaignInvocable.Req();
        request.campaignId = testCampaign.Id;
        request.accountIds = new List<Id>{testAccounts[0].Id, testAccounts[1].Id, testAccounts[2].Id};
        request.status = 'Sent';
        
        Test.startTest();
        List<AddAccountsToCampaignInvocable.Result> results = AddAccountsToCampaignInvocable.addAccounts(new List<AddAccountsToCampaignInvocable.Req>{request});
        Test.stopTest();
        
        // Проверяем результат
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].message.contains('added: 3'), 'Should indicate 3 accounts added');
        
        List<CampaignMember> members = [
            SELECT Id, CampaignId, AccountId, Status 
            FROM CampaignMember 
            WHERE CampaignId = :testCampaign.Id
        ];
        
        System.assertEquals(3, members.size(), 'Should create 3 campaign members');
    }
}
