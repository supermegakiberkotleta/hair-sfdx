public with sharing class SendLeadsToQuickBooksInvoker {
    @InvocableMethod(label='Send Leads to QuickBooks' description='Запускает батч SendLeadsToQuickBooksBatch')
    public static void runBatch(List<String> dummyInput) {
        Database.executeBatch(new SendLeadsToQuickBooksBatch(), 50);
    }
}
