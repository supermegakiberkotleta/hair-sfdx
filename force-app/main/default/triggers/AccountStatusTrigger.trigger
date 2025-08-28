// File: force-app/main/default/triggers/AccountStatusTrigger.trigger
trigger AccountStatusTrigger on Account (after insert, after update) {
    List<Account> accountsToSend = new List<Account>();

    if (Trigger.isInsert) {
        accountsToSend.addAll(Trigger.new);
    } else if (Trigger.isUpdate) {
        // Отправляем при любом изменении (можно ограничить полями при необходимости)
        accountsToSend.addAll(Trigger.new);
    }

    if (!Test.isRunningTest() && !accountsToSend.isEmpty()) {
        System.enqueueJob(new SendAccountStatusJob(accountsToSend));
        System.debug('SendAccountStatusJob поставлен в очередь для ' + accountsToSend.size() + ' аккаунтов.');
    }
}