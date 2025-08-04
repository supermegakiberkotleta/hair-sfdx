public class AccountTriggerHandler {
    public static void handleDeactivation(List<Account> accounts) {
        for (Account l : accounts) {
            if (l.Client_Type__c == 'Closed Lost') {
                l.Active_status__c = false;
                if (String.isBlank(l.Reason_for_closure__c)) {
                    l.Reason_for_closure__c.addError('Please provide a reason for closure.');
                }
            } else {
                l.Active_status__c = true;
            }
        }
    }
}