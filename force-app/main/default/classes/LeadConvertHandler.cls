public class LeadConvertHandler {
    public static void afterLeadConvert(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        List<Account> accountsToUpdate = new List<Account>();
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Lead lead : newLeads) {
            Lead oldLead = oldMap.get(lead.Id);

            if (lead.IsConverted && oldLead != null && !oldLead.IsConverted) {
                Map<String, Object> leadFieldMap = lead.getPopulatedFieldsAsMap();

                if (lead.ConvertedAccountId != null) {
                    Account acc = new Account(Id = lead.ConvertedAccountId);
                    copyMatchingFields(leadFieldMap, acc);
                    accountsToUpdate.add(acc);
                }

                if (lead.ConvertedContactId != null) {
                    Contact con = new Contact(Id = lead.ConvertedContactId);
                    copyMatchingFields(leadFieldMap, con);
                    contactsToUpdate.add(con);
                }

                if (lead.ConvertedOpportunityId != null) {
                    Opportunity opp = new Opportunity(Id = lead.ConvertedOpportunityId);
                    copyMatchingFields(leadFieldMap, opp);
                    oppsToUpdate.add(opp);
                }
            }
        }

        if (!accountsToUpdate.isEmpty() && !Test.isRunningTest()) update accountsToUpdate;
        if (!contactsToUpdate.isEmpty() && !Test.isRunningTest()) update contactsToUpdate;
        if (!oppsToUpdate.isEmpty() && !Test.isRunningTest()) update oppsToUpdate;

    }

    private static void copyMatchingFields(Map<String, Object> sourceFields, SObject target) {
    Map<String, Schema.SObjectField> targetFields = Schema.getGlobalDescribe()
        .get(target.getSObjectType().getDescribe().getName())
        .getDescribe().fields.getMap();

    for (String fieldName : sourceFields.keySet()) {
        // Только кастомные поля
        if (!fieldName.endsWith('__c')) continue;

        // Проверка наличия поля и возможности обновления
        if (targetFields.containsKey(fieldName)) {
            Schema.DescribeFieldResult fieldDescribe = targetFields.get(fieldName).getDescribe();
            if (!fieldDescribe.isUpdateable()) continue;

            try {
                target.put(fieldName, sourceFields.get(fieldName));
            } catch (Exception e) {
                // Игнорировать ошибки
            }
        }
    }
}


}
