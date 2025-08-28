// File: force-app/main/default/triggers/ContactStatusTrigger.trigger
trigger ContactStatusTrigger on Contact (after insert, after update) {
    List<Contact> contactsToSend = new List<Contact>();

    if (Trigger.isInsert) {
        contactsToSend.addAll(Trigger.new);
    } else if (Trigger.isUpdate) {
        // Можно добавить проверку на изменение конкретных полей, если нужно
        // Сейчас — отправляем при любом изменении
        contactsToSend.addAll(Trigger.new);
    }

    if (!Test.isRunningTest() && !contactsToSend.isEmpty()) {
        System.enqueueJob(new SendContactStatusJob(contactsToSend));
        System.debug('SendContactStatusJob поставлен в очередь для ' + contactsToSend.size() + ' контактов.');
    }
}