public class LeadTriggerHandler {
    public static void handleDeactivation(List<Lead> leads) {
        for (Lead l : leads) {
            if (l.Status == 'Closed Lost') {
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
