public class IncoceToLeadInstallerJob implements Queueable, Database.AllowsCallouts {
    private List<Id> invoiceIds;

    public IncoceToLeadInstallerJob(List<Id> invoiceIds) {
        this.invoiceIds = invoiceIds;
    }

    public void execute(QueueableContext context) {
        // 1. Загружаем инвойсы
        List<Invoices__c> invoices = [
            SELECT Id, Account__c, Total__c
            FROM Invoices__c
            WHERE Id IN :invoiceIds AND Account__c != null AND Lead__c = null
        ];

        Set<Id> accountIds = new Set<Id>();
        for (Invoices__c inv : invoices) {
            accountIds.add(inv.Account__c);
        }

        // 2. Загружаем сконвертированные лиды (самые новые на аккаунт)
        Map<Id, Lead> latestLeadByAccount = new Map<Id, Lead>();
        for (Lead ld : [
            SELECT Id, ConvertedAccountId, CreatedDate
            FROM Lead
            WHERE IsConverted = true AND ConvertedAccountId IN :accountIds
            ORDER BY CreatedDate DESC
        ]) {
            if (!latestLeadByAccount.containsKey(ld.ConvertedAccountId)) {
                latestLeadByAccount.put(ld.ConvertedAccountId, ld);
            }
        }

        // 3. Обновляем Lead__c в инвойсах
        Map<Id, List<Invoices__c>> invoicesByAccount = new Map<Id, List<Invoices__c>>();
        List<Invoices__c> invoicesToUpdate = new List<Invoices__c>();

        for (Invoices__c inv : invoices) {
            Id accId = inv.Account__c;
            if (latestLeadByAccount.containsKey(accId)) {
                inv.Lead__c = latestLeadByAccount.get(accId).Id;
                invoicesToUpdate.add(inv);
            }

            // собираем для подсчета Total__c
            if (!invoicesByAccount.containsKey(accId)) {
                invoicesByAccount.put(accId, new List<Invoices__c>());
            }
            invoicesByAccount.get(accId).add(inv);
        }

        if (!invoicesToUpdate.isEmpty()) {
            update invoicesToUpdate;
        }

        // 4. Считаем сумму Total__c по каждому аккаунту
        List<Account> accountsToUpdate = new List<Account>();
        for (Id accId : invoicesByAccount.keySet()) {
            Decimal sum = 0;
            for (Invoices__c inv : invoicesByAccount.get(accId)) {
                sum += (inv.Total__c != null ? inv.Total__c : 0);
            }
            accountsToUpdate.add(new Account(
                Id = accId,
                Total_Purshase__c = sum
            ));
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}