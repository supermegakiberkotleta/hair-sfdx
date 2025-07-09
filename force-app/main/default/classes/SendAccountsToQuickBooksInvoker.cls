public with sharing class SendAccountsToQuickBooksInvoker {
    @InvocableMethod(label='Send Accounts to QuickBooks' description='Запускает батч SendAccountsToQuickBooksBatch')
    public static void runBatch(List<String> dummyInput) {
        Database.executeBatch(new SendAccountsToQuickBooksBatch(), 10);
    }
}