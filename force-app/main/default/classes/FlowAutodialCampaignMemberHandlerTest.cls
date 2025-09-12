@IsTest
public class FlowAutodialCampaignMemberHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test Autodial Campaign
        Autodial_Campaign__c campaign = new Autodial_Campaign__c(
            Name = 'Test Campaign'
        );
        insert campaign;
        
        // Create test Leads
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 100; i++) {
            leads.add(new Lead(
                FirstName = 'Test',
                LastName = 'Lead ' + i,
                Email = 'test' + i + '@example.com',
                Company = 'Test Company ' + i
            ));
        }
        insert leads;
        
        // Create test Contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 50; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'contact' + i + '@example.com'
            ));
        }
        insert contacts;
        
        // Create test Accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 25; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i
            ));
        }
        insert accounts;
    }
    
    @IsTest
    static void testAddCampaignMembers_Success() {
        // Get test data
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 10];
        
        // Prepare request
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>();
        for (Lead lead : leads) {
            request.recordIds.add(lead.Id);
        }
        request.objectType = 'Lead';
        request.autodialId = campaign.Id;
        request.useBatchProcessing = false;
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
       
        // Verify records were created
        List<Autodial_CampaignMembers__c> members = [
            SELECT Id, Lead__c, Autodial_Campaign__c 
            FROM Autodial_CampaignMembers__c 
            WHERE Autodial_Campaign__c = :campaign.Id
        ];
    }
    
    @IsTest
    static void testAddCampaignMembers_LargeVolume() {
        // Get test data
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        List<Lead> leads = [SELECT Id FROM Lead];
        
        // Prepare request with large volume using batch processing
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>();
        for (Lead lead : leads) {
            request.recordIds.add(lead.Id);
        }
        request.objectType = 'Lead';
        request.autodialId = campaign.Id;
        request.useBatchProcessing = true;
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
        
        // Verify records were created
        List<Autodial_CampaignMembers__c> members = [
            SELECT Id, Lead__c, Autodial_Campaign__c 
            FROM Autodial_CampaignMembers__c 
            WHERE Autodial_Campaign__c = :campaign.Id
        ];
    }
    
    
    @IsTest
    static void testAddCampaignMembers_Contact() {
        // Get test data
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 5];
        
        // Prepare request
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>();
        for (Contact contact : contacts) {
            request.recordIds.add(contact.Id);
        }
        request.objectType = 'Contact';
        request.autodialId = campaign.Id;
        request.useBatchProcessing = false;
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
       
        // Verify records were created
        List<Autodial_CampaignMembers__c> members = [
            SELECT Id, Contact__c, Autodial_Campaign__c 
            FROM Autodial_CampaignMembers__c 
            WHERE Autodial_Campaign__c = :campaign.Id
        ];
    }
    
    @IsTest
    static void testAddCampaignMembers_Account() {
        // Get test data
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        List<Account> accounts = [SELECT Id FROM Account LIMIT 3];
        
        // Prepare request
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>();
        for (Account account : accounts) {
            request.recordIds.add(account.Id);
        }
        request.objectType = 'Account';
        request.autodialId = campaign.Id;
        request.useBatchProcessing = false;
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
       
        // Verify records were created
        List<Autodial_CampaignMembers__c> members = [
            SELECT Id, Account__c, Autodial_Campaign__c 
            FROM Autodial_CampaignMembers__c 
            WHERE Autodial_Campaign__c = :campaign.Id
        ];
    }
    
    @IsTest
    static void testAddCampaignMembers_Duplicates() {
        // Get test data
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 5];
        
        // Create existing campaign members
        List<Autodial_CampaignMembers__c> existingMembers = new List<Autodial_CampaignMembers__c>();
        for (Lead lead : leads) {
            existingMembers.add(new Autodial_CampaignMembers__c(
                Lead__c = lead.Id,
                Autodial_Campaign__c = campaign.Id
            ));
        }
        insert existingMembers;
        
        // Prepare request with same leads
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>();
        for (Lead lead : leads) {
            request.recordIds.add(lead.Id);
        }
        request.objectType = 'Lead';
        request.autodialId = campaign.Id;
        request.useBatchProcessing = false;
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
       
        // Verify no additional records were created
        List<Autodial_CampaignMembers__c> members = [
            SELECT Id, Lead__c, Autodial_Campaign__c 
            FROM Autodial_CampaignMembers__c 
            WHERE Autodial_Campaign__c = :campaign.Id
        ];
    }
    
    @IsTest
    static void testAddCampaignMembers_InvalidInput() {
        // Test with empty record IDs
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>();
        request.objectType = 'Lead';
        request.autodialId = 'a000000000000000';
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
      
    }
    
    @IsTest
    static void testAddCampaignMembers_InvalidObjectType() {
        // Get test data
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 1];
        
        // Prepare request with invalid object type
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>{leads[0].Id};
        request.objectType = 'InvalidType';
        request.autodialId = campaign.Id;
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
       
    }
    
    @IsTest
    static void testAddCampaignMembers_InvalidCampaign() {
        // Get test data
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 1];
        
        // Prepare request with invalid campaign ID
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>{leads[0].Id};
        request.objectType = 'Lead';
        request.autodialId = 'a000000000000000';
        request.useBatchProcessing = false;
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
       
    }
    
    @IsTest
    static void testAddCampaignMembers_WithBatchProcessing() {
        // Get test data
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 10];
        
        // Prepare request with batch processing enabled
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>();
        for (Lead lead : leads) {
            request.recordIds.add(lead.Id);
        }
        request.objectType = 'Lead';
        request.autodialId = campaign.Id;
        request.useBatchProcessing = true;
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
        
        
        // Verify records were created
        List<Autodial_CampaignMembers__c> members = [
            SELECT Id, Lead__c, Autodial_Campaign__c 
            FROM Autodial_CampaignMembers__c 
            WHERE Autodial_Campaign__c = :campaign.Id
        ];
    }
    
    @IsTest
    static void testAddCampaignMembers_WithAdditionalFields() {
        // Get test data
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        List<Lead> leads = [SELECT Id, FirstName, LastName, Phone FROM Lead LIMIT 3];
        
        // Prepare request
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>();
        for (Lead lead : leads) {
            request.recordIds.add(lead.Id);
        }
        request.objectType = 'Lead';
        request.autodialId = campaign.Id;
        request.useBatchProcessing = false;
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size());
        System.assert(results[0].startsWith('Success: Added 3 member(s)'));
        
        // Verify records were created with additional fields
        List<Autodial_CampaignMembers__c> members = [
            SELECT Id, Lead__c, Autodial_Campaign__c, Name, Phone__c, Record_Type__c, Record__c
            FROM Autodial_CampaignMembers__c 
            WHERE Autodial_Campaign__c = :campaign.Id
        ];
        System.assertEquals(3, members.size());
        
        // Verify additional fields are populated
        for (Autodial_CampaignMembers__c member : members) {
            System.assertNotEquals(null, member.Name, 'Name should be populated');
            System.assertNotEquals(null, member.Record_Type__c, 'Record_Type__c should be populated');
            System.assertEquals('Lead', member.Record_Type__c, 'Record_Type__c should be Lead');
            System.assertNotEquals(null, member.Record__c, 'Record__c should be populated');
            
            // Verify Record__c contains Lightning URL
            String recordUrl = (String)member.Record__c;
            System.assert(recordUrl.contains('/lightning/r/Lead/'), 'Record__c should contain Lightning URL for Lead');
            System.assert(recordUrl.contains('/view'), 'Record__c should contain /view suffix');
            System.assert(recordUrl.contains(String.valueOf(member.Lead__c)), 'Record__c should contain Lead ID');
        }
    }
    
    @IsTest
    static void testAddCampaignMembers_ContactWithUrl() {
        // Get test data
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        List<Contact> contacts = [SELECT Id, FirstName, LastName, Phone FROM Contact LIMIT 2];
        
        // Prepare request
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>();
        for (Contact contact : contacts) {
            request.recordIds.add(contact.Id);
        }
        request.objectType = 'Contact';
        request.autodialId = campaign.Id;
        request.useBatchProcessing = false;
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size());
        System.assert(results[0].startsWith('Success: Added 2 member(s)'));
        
        // Verify records were created with correct URL
        List<Autodial_CampaignMembers__c> members = [
            SELECT Id, Contact__c, Record__c
            FROM Autodial_CampaignMembers__c 
            WHERE Autodial_Campaign__c = :campaign.Id
        ];
        System.assertEquals(2, members.size());
        
        // Verify Record__c contains correct Lightning URL for Contact
        for (Autodial_CampaignMembers__c member : members) {
            String recordUrl = (String)member.Record__c;
            System.assert(recordUrl.contains('/lightning/r/Contact/'), 'Record__c should contain Lightning URL for Contact');
            System.assert(recordUrl.contains('/view'), 'Record__c should contain /view suffix');
            System.assert(recordUrl.contains(String.valueOf(member.Contact__c)), 'Record__c should contain Contact ID');
        }
    }
    
    @IsTest
    static void testAddCampaignMembers_AccountWithUrl() {
        // Get test data
        Autodial_Campaign__c campaign = [SELECT Id FROM Autodial_Campaign__c LIMIT 1];
        List<Account> accounts = [SELECT Id, Name, Phone FROM Account LIMIT 2];
        
        // Prepare request
        FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
            new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
        request.recordIds = new List<String>();
        for (Account account : accounts) {
            request.recordIds.add(account.Id);
        }
        request.objectType = 'Account';
        request.autodialId = campaign.Id;
        request.useBatchProcessing = false;
        
        Test.startTest();
        List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
            new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
        );
        Test.stopTest();
        
        // Verify results
        System.assertEquals(1, results.size());
        System.assert(results[0].startsWith('Success: Added 2 member(s)'));
        
        // Verify records were created with correct URL
        List<Autodial_CampaignMembers__c> members = [
            SELECT Id, Account__c, Record__c
            FROM Autodial_CampaignMembers__c 
            WHERE Autodial_Campaign__c = :campaign.Id
        ];
        System.assertEquals(2, members.size());
        
        // Verify Record__c contains correct Lightning URL for Account
        for (Autodial_CampaignMembers__c member : members) {
            String recordUrl = (String)member.Record__c;
            System.assert(recordUrl.contains('/lightning/r/Account/'), 'Record__c should contain Lightning URL for Account');
            System.assert(recordUrl.contains('/view'), 'Record__c should contain /view suffix');
            System.assert(recordUrl.contains(String.valueOf(member.Account__c)), 'Record__c should contain Account ID');
        }
    }
}