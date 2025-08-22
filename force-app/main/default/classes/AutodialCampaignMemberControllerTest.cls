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
}



