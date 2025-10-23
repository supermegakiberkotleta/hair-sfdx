public with sharing class CallAttemptsPanelController {
    
    /**
     * @description Gets list of Autodial_Campaign__c records sorted by creation date
     * @return List<Map<String, Object>> List of campaigns with Id and Name
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCampaigns() {
        try {
            List<Autodial_Campaign__c> campaigns = [
                SELECT Id, Name, CreatedDate
                FROM Autodial_Campaign__c
                ORDER BY CreatedDate DESC
                LIMIT 100
            ];
            
            List<Map<String, Object>> campaignOptions = new List<Map<String, Object>>();
            
            for (Autodial_Campaign__c campaign : campaigns) {
                campaignOptions.add(new Map<String, Object>{
                    'label' => campaign.Name,
                    'value' => campaign.Id
                });
            }
            
            return campaignOptions;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting campaigns: ' + e.getMessage());
        }
    }
    
    /**
     * @description Gets telephony base URL from Named Credential
     * @return String Base URL for telephony service
     */
    @AuraEnabled(cacheable=true)
    public static String getTelephonyBaseUrl() {
        try {
            // For now, return static URL to avoid LWS issues
            // In production, this should be configured via Custom Metadata or Named Credential
            return 'https://telephony.lenderpro.ai';
            
        } catch (Exception e) {
            throw new AuraHandledException('Error getting telephony URL: ' + e.getMessage());
        }
    }
}