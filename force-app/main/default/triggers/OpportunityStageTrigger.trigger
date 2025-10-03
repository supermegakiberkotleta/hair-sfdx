trigger OpportunityStageTrigger on Opportunity (after update) {

    Set<Id> toEnqueue = new Set<Id>();

    if (Trigger.isUpdate) {
        for (Opportunity opp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(opp.Id);

            // Проверяем, что StageName изменился
            if (opp.StageName != oldOpp.StageName) {
                toEnqueue.add(opp.Id);
            }
        }
    }

    // Передаём Id в очередь
    for (Id oppId : toEnqueue) {
        System.enqueueJob(new SendOpportunityStageJob((String) oppId));
    }
}