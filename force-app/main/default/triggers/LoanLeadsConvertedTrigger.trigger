trigger LoanLeadsConvertedTrigger on Lead (after update) {
    for (Lead l : Trigger.new) {
        Lead old = Trigger.oldMap.get(l.Id);

        if (
            l.Status == 'Call after' &&
            old.Status != 'Call after' &&
            l.RecordTypeId == '012Kc000000tenuIAA'
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

            if (!missingFields.isEmpty()) {
                String message = 'Before changing the status to "Call after", you must fill in the fields: '
                    + String.join(missingFields, ', ');
                l.addError(message);
            }
        }
    }
}
