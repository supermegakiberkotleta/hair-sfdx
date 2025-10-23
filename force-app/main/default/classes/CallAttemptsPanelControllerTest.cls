@isTest
public class CallAttemptsPanelControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Создаем тестовые кампании
        List<Autodial_Campaign__c> testCampaigns = new List<Autodial_Campaign__c>();
        
        for (Integer i = 1; i <= 5; i++) {
            testCampaigns.add(new Autodial_Campaign__c(
                Name = 'Test Campaign ' + i
            ));
        }
        
        insert testCampaigns;
    }
    
    @isTest
    static void testGetCampaigns() {
        // Call method
        Test.startTest();
        List<Map<String, Object>> campaigns = CallAttemptsPanelController.getCampaigns();
        Test.stopTest();
        
        // Check result
        System.assertNotEquals(null, campaigns, 'Campaigns list should not be null');
        System.assertEquals(5, campaigns.size(), 'Should be 5 campaigns');
        
        // Check data structure
        for (Map<String, Object> campaign : campaigns) {
            System.assert(campaign.containsKey('label'), 'Campaign should contain label');
            System.assert(campaign.containsKey('value'), 'Campaign should contain value');
            System.assertNotEquals(null, campaign.get('label'), 'Label should not be null');
            System.assertNotEquals(null, campaign.get('value'), 'Value should not be null');
        }
    }
    
    @isTest
    static void testGetTelephonyBaseUrl() {
        // Test getting telephony base URL
        Test.startTest();
        String url = CallAttemptsPanelController.getTelephonyBaseUrl();
        Test.stopTest();
        
        // Basic validation - just check that we get some URL back
        System.assertNotEquals(null, url, 'URL should not be null');
        System.assertNotEquals('', url, 'URL should not be empty');
    }
}
