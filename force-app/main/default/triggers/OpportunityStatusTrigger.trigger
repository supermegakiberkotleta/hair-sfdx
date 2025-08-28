// File: OpportunityStatusTrigger.trigger
trigger OpportunityStatusTrigger on Opportunity (after insert, after update) {
    List<Opportunity> opportunitiesToSend = new List<Opportunity>();

    if (Trigger.isInsert) {
        // При создании отправляем данные
        opportunitiesToSend.addAll(Trigger.new);
    } else if (Trigger.isUpdate) {
        // При обновлении — только если изменился StageName
        for (Opportunity newOpp : Trigger.new) {
            Opportunity oldOpp = Trigger.oldMap.get(newOpp.Id);
            if (oldOpp.StageName != newOpp.StageName) {
                System.debug('Стадия сделки изменена: ' + oldOpp.StageName + ' -> ' + newOpp.StageName);
                opportunitiesToSend.add(newOpp);
            }
        }
    }

    // Отправляем через Queueable (не в тестах)
    if (!Test.isRunningTest() && !opportunitiesToSend.isEmpty()) {
        System.enqueueJob(new SendOpportunityStatusJob(opportunitiesToSend));
        System.debug('SendOpportunityStatusJob поставлен в очередь для ' + opportunitiesToSend.size() + ' сделок.');
    }
}