@IsTest
private class AutodialCampaignIterationControllerTest {
    @IsTest
    static void testGetIterations_basic() {
        // Create a campaign record
        Autodial_Campaign__c camp = new Autodial_Campaign__c(Name = 'Test Campaign');
        insert camp;

        // Create iterations
        Autodial_CampaignIteration__c it1 = new Autodial_CampaignIteration__c(
            Name = 'It 1',
            Autodial_Campaign__c = camp.Id,
            Order__c = 1,
            Start_Date__c = System.now().addDays(-1),
            End_Date__c = System.now(),
            Number__c = '+10000000001',
            Total_Calls__c = 10,
            Total_Successful_Calls__c = 3,
            Total_No_Answer_Calls__c = 5,
            Total_Failed_Calls__c = 2
        );
        Autodial_CampaignIteration__c it2 = new Autodial_CampaignIteration__c(
            Name = 'It 2',
            Autodial_Campaign__c = camp.Id,
            Order__c = 2,
            Start_Date__c = System.now(),
            End_Date__c = System.now().addDays(1),
            Number__c = '+10000000002',
            Total_Calls__c = 20,
            Total_Successful_Calls__c = 7,
            Total_No_Answer_Calls__c = 9,
            Total_Failed_Calls__c = 4
        );
        insert new List<Autodial_CampaignIteration__c>{ it1, it2 };

        Test.startTest();
        List<AutodialCampaignIterationController.IterationDTO> dtos = AutodialCampaignIterationController.getIterations(camp.Id);
        Test.stopTest();

        System.assertEquals(2, dtos.size(), 'Should return two iterations');
        System.assertEquals('It 1', dtos[0].name);
        System.assertEquals(Decimal.valueOf(1), dtos[0].orderNumber);
        System.assertEquals('+10000000001', dtos[0].phoneNumber);
        System.assertEquals(Decimal.valueOf(10), dtos[0].totalCalls);
        System.assertEquals(Decimal.valueOf(3), dtos[0].totalSuccessfulCalls);
        System.assertEquals(Decimal.valueOf(5), dtos[0].totalNoAnswerCalls);
        System.assertEquals(Decimal.valueOf(2), dtos[0].totalFailedCalls);
    }
}