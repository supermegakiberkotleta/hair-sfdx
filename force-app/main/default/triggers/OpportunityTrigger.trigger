trigger OpportunityTrigger on Opportunity (after insert, after update) {

    //Boolean inAsync = System.isBatch() || System.isFuture() || System.isQueueable();

    //if (Trigger.isAfter && Trigger.isInsert && !inAsync) {
    //    for (Opportunity opp : Trigger.new) {
    //        System.enqueueJob(new SendOpportunityUpdateJob(
    //                String.valueOf(opp.Id),
    //                String.valueOf(opp.SlaesForceLeadId__c),
    //                String.valueOf(opp.Report_FILE__c)
    //        ));
    //    }
    //}

    if (!Trigger.isAfter) return;

    Set<Id> toEnqueue = new Set<Id>();

    if (Trigger.isInsert) {
        for (Opportunity opp : Trigger.new) {
            if (opp.SlaesForceLeadId__c != null && opp.Report_FILE__c != null) {
                toEnqueue.add(opp.Id);
            }
        }
    }

    if (Trigger.isUpdate) {
        for (Opportunity opp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);

            Boolean fieldsChanged =
                (opp.SlaesForceLeadId__c != oldOpp.SlaesForceLeadId__c) ||
                (opp.Report_FILE__c != oldOpp.Report_FILE__c);

            if (fieldsChanged && opp.SlaesForceLeadId__c != null && opp.Report_FILE__c != null) {
                toEnqueue.add(opp.Id);
            }
        }
    }

    for (Id oppId : toEnqueue) {
        Opportunity opp = Trigger.newMap.get(oppId);
        System.enqueueJob(new SendOpportunityUpdateJob(
            (String)opp.Id,
            (String)opp.SlaesForceLeadId__c,
            (String)opp.Report_FILE__c
        ));
    }

    for (Opportunity opp : Trigger.new) {
        if (opp.Lender_type__c != null) {
            SendLenderTypeService.sendLenderType(opp.Id, opp.Lender_type__c);
        }
    }
}