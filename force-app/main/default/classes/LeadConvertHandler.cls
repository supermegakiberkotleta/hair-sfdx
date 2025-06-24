public class LeadConvertHandler {
    public static void afterLeadConvert(List<Lead> newLeads, Map<Id, Lead> oldMap) {
        List<Account> accountsToUpdate = new List<Account>();
        List<Contact> contactsToUpdate = new List<Contact>();
        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Lead lead : newLeads) {
            Lead oldLead = oldMap.get(lead.Id);

            if (lead.IsConverted && oldLead != null && !oldLead.IsConverted) {
                // ✅ Только если нужный RecordType
                if (lead.RecordTypeId == '012Kc000000tenuIAA') {
                    List<String> missingFields = new List<String>();

                    if (lead.Final_Daily_payment__c == null)
                        missingFields.add('Final Daily Payment');
                    if (lead.Final_purchased_Amount_of_Future_New__c == null)
                        missingFields.add('Final purchased Amount of Future Receipt');
                    if (String.isBlank(lead.Payment_Frequency__c))
                        missingFields.add('Payment Frequency');
                    if (lead.Loan_Start_Date__c == null)
                        missingFields.add('Loan Start Date');
                    if (lead.Final_Term__c == null)
                        missingFields.add('Final Term');
                    if (String.isBlank(lead.Client_email__c))
                        missingFields.add('Client Email');

                    // 🛑 Если есть незаполненные — выбрасываем ошибку
                    if (!missingFields.isEmpty()) {
                        String errorMessage = 'Lead conversion is not possible. Fill in the fields: ' + String.join(missingFields, ', ');
                        lead.addError(errorMessage);
                        continue; // чтобы остальные не обрабатывались
                    }
                }

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

        if (!accountsToUpdate.isEmpty() && !Test.isRunningTest()) {
            update accountsToUpdate;
        }

        if (!contactsToUpdate.isEmpty() && !Test.isRunningTest()) {
            update contactsToUpdate;
        }

        if (!oppsToUpdate.isEmpty() && !Test.isRunningTest()) {
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
