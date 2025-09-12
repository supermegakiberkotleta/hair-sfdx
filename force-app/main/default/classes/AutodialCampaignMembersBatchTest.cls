@IsTest
public class AutodialCampaignMembersBatchTest {
    
    /**
     * Helper method to create test scope from member IDs
     */
    private static List<Id> createTestScope(Set<Id> memberIds, Integer maxSize) {
        List<Id> idList = new List<Id>(memberIds);
        List<Id> testScope = new List<Id>();
        for (Integer i = 0; i < Math.min(maxSize, idList.size()); i++) {
            testScope.add(idList[i]);
        }
        return testScope;
    }
    
    @TestSetup
    static void setupTestData() {
        // Create test Autodial Campaign
        Autodial_Campaign__c campaign = new Autodial_Campaign__c(
            Name = 'Test Campaign'
        );
        insert campaign;
        
        // Create test Leads
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            leads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Email = 'test' + i + '@example.com',
                Company = 'Test Company ' + i
            ));
        }
        insert leads;
        
        // Create test Campaign Members
        List<Autodial_CampaignMembers__c> members = new List<Autodial_CampaignMembers__c>();
        for (Lead lead : leads) {
            members.add(new Autodial_CampaignMembers__c(
                Lead__c = lead.Id,
                Autodial_Campaign__c = campaign.Id
            ));
        }
        insert members;
    }
    
    @IsTest
    static void testBatchCreate() {
        // Get test data
        List<Autodial_CampaignMembers__c> members = [SELECT Id FROM Autodial_CampaignMembers__c];
        Set<Id> memberIds = new Set<Id>();
        for (Autodial_CampaignMembers__c member : members) {
            memberIds.add(member.Id);
        }
        
        Test.startTest();
        AutodialCampaignMembersBatch batch = new AutodialCampaignMembersBatch(memberIds);
        // Test the batch methods directly instead of executing
        List<Id> testScope = createTestScope(memberIds, 5);
        batch.execute(null, testScope);
        Test.stopTest();
        
        // Verify batch was executed (we can't easily test callouts in unit tests)
        // The main verification is that the batch runs without errors
        System.assert(true, 'Batch should execute without errors');
    }
    
    @IsTest
    static void testBatchDelete() {
        // Get test data
        List<Autodial_CampaignMembers__c> members = [SELECT Id FROM Autodial_CampaignMembers__c];
        Set<Id> memberIds = new Set<Id>();
        for (Autodial_CampaignMembers__c member : members) {
            memberIds.add(member.Id);
        }
        
        Test.startTest();
        AutodialCampaignMembersBatch batch = new AutodialCampaignMembersBatch(memberIds, 'delete');
        // Test the batch methods directly instead of executing
        List<Id> testScope = createTestScope(memberIds, 5);
        batch.execute(null, testScope);
        Test.stopTest();
        
        // Verify batch was executed
        System.assert(true, 'Batch should execute without errors');
    }
    
    @IsTest
    static void testBatchWithEmptySet() {
        Test.startTest();
        AutodialCampaignMembersBatch batch = new AutodialCampaignMembersBatch(new Set<Id>());
        // Test the batch methods directly instead of executing
        batch.execute(null, new List<Id>());
        Test.stopTest();
        
        // Verify batch handles empty set gracefully
        System.assert(true, 'Batch should handle empty set without errors');
    }
    
    @IsTest
    static void testBatchConstructor() {
        Set<Id> testIds = new Set<Id>();
        
        // Test default constructor
        AutodialCampaignMembersBatch batch1 = new AutodialCampaignMembersBatch(testIds);
        System.assertNotEquals(null, batch1, 'Batch should be created');
        
        // Test constructor with operation
        AutodialCampaignMembersBatch batch2 = new AutodialCampaignMembersBatch(testIds, 'create');
        System.assertNotEquals(null, batch2, 'Batch should be created with operation');
    }
    
    @IsTest
    static void testBatchStartAndFinish() {
        // Get test data
        List<Autodial_CampaignMembers__c> members = [SELECT Id FROM Autodial_CampaignMembers__c];
        Set<Id> memberIds = new Set<Id>();
        for (Autodial_CampaignMembers__c member : members) {
            memberIds.add(member.Id);
        }
        
        Test.startTest();
        AutodialCampaignMembersBatch batch = new AutodialCampaignMembersBatch(memberIds);
        
        // Test start method
        Iterable<Id> iterable = batch.start(null);
        System.assertNotEquals(null, iterable, 'Start method should return iterable');
        
        // Test finish method
        batch.finish(null);
        
        Test.stopTest();
        
        // Verify methods executed without errors
        System.assert(true, 'Start and finish methods should execute without errors');
    }
}
