@IsTest
private class AutodialCampaignMemberControllerTest {

	@IsTest
	static void testAddMembers_Idempotent() {
		// Create Campaign (custom object Autodial_Campaign__c)
		SObjectType campaignType = Autodial_Campaign__c.SObjectType;
		Autodial_Campaign__c camp = (Autodial_Campaign__c)campaignType.newSObject();
		camp.Name = 'Test Campaign';
		insert camp;

		// Create Leads
		Lead l1 = new Lead(LastName = 'One', Company = 'ACo', Status = 'New');
		Lead l2 = new Lead(LastName = 'Two', Company = 'BCo', Status = 'New');
		insert new List<Lead>{ l1, l2 };

		Test.startTest();
		AutodialCampaignMemberController.AddMembersResult r1 = AutodialCampaignMemberController.addMembers(camp.Id, new List<Id>{ l1.Id, l2.Id });
		AutodialCampaignMemberController.AddMembersResult r2 = AutodialCampaignMemberController.addMembers(camp.Id, new List<Id>{ l1.Id });
		Test.stopTest();

		System.assertEquals(true, r1.success);
		System.assertEquals(2, r1.createdCount);
		System.assertEquals(0, r1.skippedCount);
		System.assertEquals(true, r2.success);
		System.assertEquals(0, r2.createdCount);
		System.assertEquals(1, r2.skippedCount);

		// Verify records exist
		List<Autodial_CampaignMembers__c> mems = [
			SELECT Id, Autodial_Campaign__c, Lead__c
			FROM Autodial_CampaignMembers__c
			WHERE Autodial_Campaign__c = :camp.Id
		];
		System.assertEquals(2, mems.size());
	}

	@IsTest
	static void testSearchLeadsReturnsRows() {
		Lead l = new Lead(LastName = 'Searchable', Company = 'SearchCo', Status = 'New');
		insert l;

		Test.startTest();
		List<AutodialCampaignMemberController.LeadRow> rows = AutodialCampaignMemberController.searchLeads('Search', 10);
		Test.stopTest();

		System.assert(rows.size() > 0);
	}

	@IsTest
	static void testSearchContactsReturnsRows() {
		Account acc = new Account(Name = 'Search Acc');
		insert acc;
		Contact c = new Contact(LastName = 'Searchable', AccountId = acc.Id);
		insert c;

		Test.startTest();
		List<AutodialCampaignMemberController.ContactRow> rows = AutodialCampaignMemberController.searchContacts('Search', 10);
		Test.stopTest();

		System.assert(rows.size() > 0);
	}

	@IsTest
	static void testSearchAccountsReturnsRows() {
		Account acc = new Account(Name = 'Searchable Account');
		insert acc;

		Test.startTest();
		List<AutodialCampaignMemberController.AccountRow> rows = AutodialCampaignMemberController.searchAccounts('Searchable', 10);
		Test.stopTest();

		System.assert(rows.size() > 0);
	}

	@IsTest
	static void testAddMembersGenericLead_Idempotent() {
		Autodial_Campaign__c camp = new Autodial_Campaign__c(Name = 'Gen Lead Camp');
		insert camp;
		Lead l1 = new Lead(LastName = 'GL One', Company = 'ACo', Status = 'New');
		Lead l2 = new Lead(LastName = 'GL Two', Company = 'BCo', Status = 'New');
		insert new List<Lead>{ l1, l2 };

		Test.startTest();
		AutodialCampaignMemberController.AddMembersResult r1 = AutodialCampaignMemberController.addMembersGeneric(camp.Id, 'lead', new List<Id>{ l1.Id, l2.Id });
		AutodialCampaignMemberController.AddMembersResult r2 = AutodialCampaignMemberController.addMembersGeneric(camp.Id, 'lead', new List<Id>{ l1.Id });
		Test.stopTest();

		System.assertEquals(true, r1.success);
		System.assertEquals(2, r1.createdCount);
		System.assertEquals(0, r1.skippedCount);
		System.assertEquals(true, r2.success);
		System.assertEquals(0, r2.createdCount);
		System.assertEquals(1, r2.skippedCount);

		List<Autodial_CampaignMembers__c> mems = [
			SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :camp.Id AND Lead__c IN :new List<Id>{ l1.Id, l2.Id }
		];
		System.assertEquals(2, mems.size());
	}

	@IsTest
	static void testAddMembersGenericContact_Idempotent() {
		Autodial_Campaign__c camp = new Autodial_Campaign__c(Name = 'Gen Contact Camp');
		insert camp;
		Account acc = new Account(Name = 'ACC for Contact');
		insert acc;
		Contact c1 = new Contact(LastName = 'GC One', AccountId = acc.Id);
		Contact c2 = new Contact(LastName = 'GC Two', AccountId = acc.Id);
		insert new List<Contact>{ c1, c2 };

		Test.startTest();
		AutodialCampaignMemberController.AddMembersResult r1 = AutodialCampaignMemberController.addMembersGeneric(camp.Id, 'contact', new List<Id>{ c1.Id, c2.Id });
		AutodialCampaignMemberController.AddMembersResult r2 = AutodialCampaignMemberController.addMembersGeneric(camp.Id, 'contact', new List<Id>{ c1.Id });
		Test.stopTest();

		System.assertEquals(true, r1.success);
		System.assertEquals(2, r1.createdCount);
		System.assertEquals(0, r1.skippedCount);
		System.assertEquals(true, r2.success);
		System.assertEquals(0, r2.createdCount);
		System.assertEquals(1, r2.skippedCount);

		List<Autodial_CampaignMembers__c> mems = [
			SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :camp.Id AND Contact__c IN :new List<Id>{ c1.Id, c2.Id }
		];
		System.assertEquals(2, mems.size());
	}

	@IsTest
	static void testAddMembersGenericAccount_Idempotent() {
		Autodial_Campaign__c camp = new Autodial_Campaign__c(Name = 'Gen Account Camp');
		insert camp;
		Account a1 = new Account(Name = 'GA One');
		Account a2 = new Account(Name = 'GA Two');
		insert new List<Account>{ a1, a2 };

		Test.startTest();
		AutodialCampaignMemberController.AddMembersResult r1 = AutodialCampaignMemberController.addMembersGeneric(camp.Id, 'account', new List<Id>{ a1.Id, a2.Id });
		AutodialCampaignMemberController.AddMembersResult r2 = AutodialCampaignMemberController.addMembersGeneric(camp.Id, 'account', new List<Id>{ a1.Id });
		Test.stopTest();

		System.assertEquals(true, r1.success);
		System.assertEquals(2, r1.createdCount);
		System.assertEquals(0, r1.skippedCount);
		System.assertEquals(true, r2.success);
		System.assertEquals(0, r2.createdCount);
		System.assertEquals(1, r2.skippedCount);

		List<Autodial_CampaignMembers__c> mems = [
			SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :camp.Id AND Account__c IN :new List<Id>{ a1.Id, a2.Id }
		];
		System.assertEquals(2, mems.size());
	}

}