trigger InvoicesTrigger on Invoices__c (after insert) {
    List<Id> idsToProcess = new List<Id>();

    for (Invoices__c inv : Trigger.new) {
        if (inv.Account__c != null && inv.Lead__c == null) {
            idsToProcess.add(inv.Id);
        }
    }

    if (!idsToProcess.isEmpty()) {
        System.enqueueJob(new IncoceToLeadInstallerJob(idsToProcess));
    }
}
