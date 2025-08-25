@IsTest
private class AutodialCampaignMembersMassDeleteCtrlTest {

    @IsTest
    static void testDoDelete_Success() {
        // Prepare data: campaign, leads, and campaign members
        Autodial_Campaign__c camp = new Autodial_Campaign__c(Name = 'Test Camp');
        insert camp;

        Lead l1 = new Lead(LastName = 'One', Company = 'ACo', Status = 'New');
        Lead l2 = new Lead(LastName = 'Two', Company = 'BCo', Status = 'New');
        insert new List<Lead>{ l1, l2 };

        Autodial_CampaignMembers__c m1 = new Autodial_CampaignMembers__c(
            Autodial_Campaign__c = camp.Id,
            Lead__c = l1.Id
        );
        Autodial_CampaignMembers__c m2 = new Autodial_CampaignMembers__c(
            Autodial_Campaign__c = camp.Id,
            Lead__c = l2.Id
        );
        insert new List<Autodial_CampaignMembers__c>{ m1, m2 };

        // StandardSetController over the records; mark them selected
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(
            [SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :camp.Id]
        );
        ssc.setPageSize(2000);
        // Select both
        List<SObject> selected = new List<SObject>();
        for (Autodial_CampaignMembers__c rec : (List<Autodial_CampaignMembers__c>)ssc.getRecords()) {
            selected.add(rec);
        }
        ssc.setSelected(selected);

        Test.startTest();
        AutodialCampaignMembersMassDeleteCtrl ctrl = new AutodialCampaignMembersMassDeleteCtrl(ssc);
        PageReference pr = ctrl.doDelete();
        Test.stopTest();

        // All selected must be deleted
        Integer remained = [SELECT COUNT() FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :camp.Id];
        System.assertEquals(0, remained, 'All selected campaign members should be deleted');

        // Return reference should attempt redirect back
        System.assertNotEquals(null, pr);
    }

    @IsTest
    static void testDoDelete_NoSelection() {
        // Prepare data: campaign and a member, but do not select anything
        Autodial_Campaign__c camp = new Autodial_Campaign__c(Name = 'Test Camp 2');
        insert camp;

        Lead l = new Lead(LastName = 'Three', Company = 'CCo', Status = 'New');
        insert l;

        Autodial_CampaignMembers__c m = new Autodial_CampaignMembers__c(
            Autodial_Campaign__c = camp.Id,
            Lead__c = l.Id
        );
        insert m;

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(
            [SELECT Id FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :camp.Id]
        );
        ssc.setPageSize(2000);
        // Explicitly set empty selection
        ssc.setSelected(new List<SObject>());

        Test.startTest();
        AutodialCampaignMembersMassDeleteCtrl ctrl = new AutodialCampaignMembersMassDeleteCtrl(ssc);
        PageReference pr = ctrl.doDelete();
        Test.stopTest();

        // Should not delete anything
        Integer remained = [SELECT COUNT() FROM Autodial_CampaignMembers__c WHERE Autodial_Campaign__c = :camp.Id];
        System.assertEquals(1, remained, 'No records should be deleted when nothing selected');
        System.assertEquals(null, pr, 'Should return null on no selection');
    }
}


