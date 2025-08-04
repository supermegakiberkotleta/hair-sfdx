trigger LoanLeadsConvertedTrigger on Lead (after update) {
    List<Id> leadsToConvert = new List<Id>();

    for (Lead l : Trigger.new) {
        Lead old = Trigger.oldMap.get(l.Id);

        if (
            l.Status == 'Call after' &&
            old.Status != 'Call after' &&
            l.RecordType.DeveloperName == 'Loan_Leads'
        ) {
            List<String> missingFields = new List<String>();

            if (l.Final_Daily_payment__c == null)
                missingFields.add('Final Daily Payment');
            if (l.Final_purchased_Amount_of_Future_New__c == null)
                missingFields.add('Final Purchased Amount of Future');
            if (String.isBlank(l.Payment_Frequency__c))
                missingFields.add('Payment Frequency');
            if (l.Loan_Start_Date__c == null)
                missingFields.add('Loan Start Date');
            if (String.isBlank(l.Final_Term__c))
                missingFields.add('Final Term');
            if (String.isBlank(l.Client_email__c))
                missingFields.add('Client Email');
            // Lender_type__c picklist values: Boostra, Liberty, Eduelevator, Biz Capital
            if (String.isBlank(l.Lender_type__c))
                missingFields.add('Lender Type');

            if (!missingFields.isEmpty()) {
                // Показываем информационное сообщение вместо ошибки
                l.addError('Please use the "Validate & Convert" button to fill in required fields and convert this lead.');
            } else {
                leadsToConvert.add(l.Id); // ✅ Только если нет ошибок
            }
        }
    }

    if (!leadsToConvert.isEmpty()) {
        System.enqueueJob(new LoanLeadsConvertedBatchStarter(leadsToConvert));
    }
}