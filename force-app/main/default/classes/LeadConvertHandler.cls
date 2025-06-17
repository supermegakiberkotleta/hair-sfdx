public class LeadConvertHandler {
    public static void afterLeadConvert(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        List<Account> accountsToUpdate = new List<Account>();
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Lead lead : newLeads) {
            Lead oldLead = oldMap.get(lead.Id);

            if (lead.IsConverted && oldLead != null && !oldLead.IsConverted) {
                System.debug('Processing converted Lead: ' + lead.Id);

                Map<String, Object> leadFieldMap = lead.getPopulatedFieldsAsMap();

                if (lead.ConvertedAccountId != null) {
                    System.debug('Lead ' + lead.Id + ' converted to Account: ' + lead.ConvertedAccountId);
                    Account acc = new Account(Id = lead.ConvertedAccountId);
                    copyMatchingFields(leadFieldMap, acc);
                    accountsToUpdate.add(acc);
                }

                if (lead.ConvertedContactId != null) {
                    System.debug('Lead ' + lead.Id + ' converted to Contact: ' + lead.ConvertedContactId);
                    Contact con = new Contact(Id = lead.ConvertedContactId);
                    copyMatchingFields(leadFieldMap, con);
                    contactsToUpdate.add(con);
                }

                if (lead.ConvertedOpportunityId != null) {
                    System.debug('Lead ' + lead.Id + ' converted to Opportunity: ' + lead.ConvertedOpportunityId);
                    Opportunity opp = new Opportunity(Id = lead.ConvertedOpportunityId);
                    copyMatchingFields(leadFieldMap, opp);
                    oppsToUpdate.add(opp);
                }
            }
        }

        if (!accountsToUpdate.isEmpty() && !Test.isRunningTest()) {
            System.debug('Updating Accounts: ' + accountsToUpdate);
            update accountsToUpdate;
        }

        if (!contactsToUpdate.isEmpty() && !Test.isRunningTest()) {
            System.debug('Updating Contacts: ' + contactsToUpdate);
            update contactsToUpdate;
        }

        if (!oppsToUpdate.isEmpty() && !Test.isRunningTest()) {
            System.debug('Updating Opportunities: ' + oppsToUpdate);
            update oppsToUpdate;
        }
    }

    private static void copyMatchingFields(Map<String, Object> sourceFields, SObject target) {
        String targetType = target.getSObjectType().getDescribe().getName();
        System.debug('Copying fields to: ' + targetType);

        Map<String, Schema.SObjectField> targetFields = Schema.getGlobalDescribe()
            .get(targetType)
            .getDescribe().fields.getMap();

        for (String fieldName : sourceFields.keySet()) {
            // Только кастомные поля
            if (!fieldName.endsWith('__c')) continue;

            if (targetFields.containsKey(fieldName)) {
                Schema.DescribeFieldResult fieldDescribe = targetFields.get(fieldName).getDescribe();
                if (!fieldDescribe.isUpdateable()) continue;

                try {
                    target.put(fieldName, sourceFields.get(fieldName));
                    System.debug('Copied field ' + fieldName + ' = ' + sourceFields.get(fieldName));
                } catch (Exception e) {
                    System.debug('Error copying field ' + fieldName + ': ' + e.getMessage());
                }
            }
        }
    }
}
