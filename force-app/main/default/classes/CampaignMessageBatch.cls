global class CampaignMessageBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    Id campaignId;
    String channel;
    String message;
    String ContentVersionId;
    Integer successCount = 0;

    global CampaignMessageBatch(Id campaignId) {
        this.campaignId = campaignId;
        System.debug('### Constructor: campaignId = ' + campaignId);
        System.debug('### start(): Fetching campaign info');
        Campaign camp = [
            SELECT Id, Type, Message__c, CampaignImageId 
            FROM Campaign 
            WHERE Id = :campaignId
        ];
        this.channel = camp.Type;
        this.message = camp.Message__c;

        if (camp.CampaignImageId != null) {

            ContentVersion cv = [
                SELECT Id, ContentDocumentId 
                FROM ContentVersion 
                WHERE ContentDocumentId = :camp.CampaignImageId 
                ORDER BY VersionNumber DESC 
                LIMIT 1
            ];

           this.ContentVersionId = cv.Id;
           System.debug('🔗 ContentVersionId: ' + ContentVersionId);

        }
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, LeadId, ContactId, AccountId FROM CampaignMember WHERE CampaignId = :campaignId
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        System.debug('### execute(): Processing ' + scope.size() + ' CampaignMembers');
        
        Set<Id> leadIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for (CampaignMember cm : (List<CampaignMember>)scope) {
            if (cm.LeadId != null) leadIds.add(cm.LeadId);
            if (cm.ContactId != null) contactIds.add(cm.ContactId);
            if (cm.AccountId != null) accountIds.add(cm.AccountId);
        }

        Map<Id, Lead> leads = new Map<Id, Lead>([
            SELECT Id, Facebook_PSID__c, Instagram_PSID__c, WhatsApp_ID__c, Phone FROM Lead WHERE Id IN :leadIds
        ]);
        Map<Id, Contact> contacts = new Map<Id, Contact>([
            SELECT Id, Facebook_PSID__c, Instagram_PSID__c, WhatsApp_ID__c, Phone FROM Contact WHERE Id IN :contactIds
        ]);
        Map<Id, Account> accounts = new Map<Id, Account>([
            SELECT Id, Facebook_PSID__c, Instagram_PSID__c, WhatsApp_ID__c, Phone FROM Account WHERE Id IN :accountIds
        ]);

        Set<Id> processedIds = new Set<Id>();

        for (CampaignMember cm : (List<CampaignMember>)scope) {
            SObject rec;
            if (cm.LeadId != null && leads.containsKey(cm.LeadId) && !processedIds.contains(cm.LeadId)) {
                rec = leads.get(cm.LeadId);
                processedIds.add(cm.LeadId);
            } else if (cm.ContactId != null && contacts.containsKey(cm.ContactId) && !processedIds.contains(cm.ContactId)) {
                rec = contacts.get(cm.ContactId);
                processedIds.add(cm.ContactId);
            } else if (cm.AccountId != null && accounts.containsKey(cm.AccountId) && !processedIds.contains(cm.AccountId)) {
                rec = accounts.get(cm.AccountId);
                processedIds.add(cm.AccountId);
            }

            if (rec != null) {
                try {
                    String chatId = CampaignMessageUtils.getChatId(rec, channel);
                    System.debug('### execute(): chatId = ' + chatId + ' for record Id = ' + rec.Id);
                    if (String.isNotBlank(chatId)) {
                        Boolean success = CampaignMessageUtils.sendMessage(chatId, message, channel);
                        System.debug('### execute(): Message sent = ' + success + ' for record Id = ' + rec.Id);
                        if (success && String.isNotBlank(ContentVersionId)) {
                            Boolean fileSent = CampaignMessageUtils.sendSalesforceFile(chatId, ContentVersionId, channel);
                            System.debug('### File sent = ' + fileSent + ' for record Id = ' + rec.Id);
                        }
                        if (success) successCount++;
                    } else {
                        System.debug('### execute(): chatId is blank, skipping');
                    }
                } catch (Exception ex) {
                    System.debug('### execute(): Error processing record Id = ' + rec.Id + ' - ' + ex.getMessage());
                }
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        try {
            System.debug('### finish(): Updating campaign with successCount = ' + successCount);
            Campaign c = [SELECT Id FROM Campaign WHERE Id = :campaignId];
            c.Status = 'Completed';
            c.Success_Count__c = successCount;
            update c;
            System.debug('### finish(): Campaign updated: ' + c.Id);
        } catch (Exception ex) {
            System.debug('### finish(): Error updating campaign - ' + ex.getMessage());
        }
    }

}