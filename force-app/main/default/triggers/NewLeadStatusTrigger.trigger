trigger NewLeadStatusTrigger on Lead (after update) {
    for (Lead newLead : Trigger.new) {
        Lead oldLead = Trigger.oldMap.get(newLead.Id);

        // Проверка на изменение статуса
        if (oldLead.Status != newLead.Status) {
            System.debug('Статус лида изменён: ' + oldLead.Status + ' -> ' + newLead.Status);

            // Отправляем webhook через Queueable
            if (!Test.isRunningTest()) {
                System.enqueueJob(new SendLeadStatusJob(newLead));
                System.debug('SendLeadStatusJob поставлен в очередь для лида: ' + newLead.Id);
            }
        }
    }
}