global class CampaignMessageBatchDebug implements Database.Batchable<SObject> {

    Id campaignId;
    String channel;
    String message;
    Integer successCount = 0;

    global CampaignMessageBatchDebug(Id campaignId) {
        this.campaignId = campaignId;
        System.debug('🆕 Constructor: campaignId = ' + campaignId);
        System.debug('🔍 start(): Loading campaign');
        Campaign camp = [SELECT Id, Type, Message__c FROM Campaign WHERE Id = :campaignId];
        this.channel = camp.Type;
        this.message = camp.Message__c;
        System.debug('✅ start(): Campaign loaded. Type = ' + camp.Type + ', Message = ' + message);

    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator([
            SELECT Id, LeadId, ContactId, AccountId FROM CampaignMember WHERE CampaignId = :campaignId
        ]);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        System.debug('⚙️ execute(): Processing ' + scope.size() + ' CampaignMembers');

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

        for (CampaignMember cm : (List<CampaignMember>)scope) {
            SObject rec;
            if (cm.LeadId != null && leads.containsKey(cm.LeadId)) {
                rec = leads.get(cm.LeadId);
            } else if (cm.ContactId != null && contacts.containsKey(cm.ContactId)) {
                rec = contacts.get(cm.ContactId);
            } else if (cm.AccountId != null && accounts.containsKey(cm.AccountId)) {
                rec = accounts.get(cm.AccountId);
            }

            if (rec != null) {
                System.debug('➡️ Processing record Id = ' + rec.Id);
                try {
                    System.debug('📦 Record: ' + JSON.serializePretty(rec));
                    String chatId = CampaignMessageUtilsDebug.getChatId(rec, channel);
                    if (String.isNotBlank(chatId)) {
                        Boolean success = CampaignMessageUtilsDebug.sendMessage(chatId, message, channel);
                        if (success) {
                            successCount++;
                            System.debug('✅ Message "sent" successfully. Total successCount = ' + successCount);
                        } else {
                            System.debug('⚠️ Failed to "send" message.');
                        }
                    } else {
                        System.debug('⛔ chatId is null or blank, skipping.');
                    }
                } catch (Exception ex) {
                    System.debug('❌ Exception while processing record: ' + ex.getMessage());
                }
            } else {
                System.debug('🚫 No related record found for CampaignMember Id = ' + cm.Id);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('🏁 finish(): Finalizing. Total successCount = ' + successCount);
        try {
            Campaign c = [SELECT Id FROM Campaign WHERE Id = :campaignId];
            c.Status = 'Completed';
            c.Success_Count__c = successCount;
            update c;
            System.debug('✅ Campaign updated: ' + c.Id);
        } catch (Exception ex) {
            System.debug('❌ finish(): Error updating campaign - ' + ex.getMessage());
        }
    }
}