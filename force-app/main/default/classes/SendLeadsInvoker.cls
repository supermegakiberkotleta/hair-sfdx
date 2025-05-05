public with sharing class SendLeadsInvoker {
    @InvocableMethod(label='Send Leads to QuickBooks')
    public static void invoke(List<String> dummy) {
        System.enqueueJob(new SendLeadsToQuickBooks());
    }
}
