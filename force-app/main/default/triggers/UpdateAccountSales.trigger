trigger UpdateAccountSales on Account (before update) {
    // Карта: AccountId → Map<Year, NetIncome>
    Map<Id, Map<String, Decimal>> accountYearToNetIncome = new Map<Id, Map<String, Decimal>>();

    // Собираем ID аккаунтов
    Set<Id> accountIds = new Set<Id>();
    for (Account acc : Trigger.new) {
        accountIds.add(acc.Id);
    }

    // Получаем все поля аккаунта, которые соответствуют шаблону Total_Client_Sales_for_YYYY__c
    Map<String, String> yearToFieldName = new Map<String, String>();
    for (Schema.SObjectField field : Schema.SObjectType.Account.fields.getMap().values()) {
        String fieldName = field.getDescribe().getName();
        if (fieldName.startsWith('Total_Client_Sales_for_') && fieldName.endsWith('__c')) {
            String year = fieldName.replace('Total_Client_Sales_for_', '').replace('__c', '');
            if (Pattern.matches('\\d{4}', year)) {
                yearToFieldName.put(year, fieldName);
            }
        }
    }

    // Загружаем записи Sales_from_QuickBooks__c по годам
    List<String> years = new List<String>(yearToFieldName.keySet());
    for (Sales_from_QuickBooks__c sale : [
        SELECT Account__c, Name, Net_income__c
        FROM Sales_from_QuickBooks__c
        WHERE Account__c IN :accountIds AND Name IN :years
    ]) {
        if (!accountYearToNetIncome.containsKey(sale.Account__c)) {
            accountYearToNetIncome.put(sale.Account__c, new Map<String, Decimal>());
        }
        accountYearToNetIncome.get(sale.Account__c).put(sale.Name, sale.Net_income__c);
    }

    // Устанавливаем значения в поля Account по году
    for (Account acc : Trigger.new) {
        Map<String, Decimal> yearToIncome = accountYearToNetIncome.get(acc.Id);
        if (yearToIncome != null) {
            for (String year : yearToIncome.keySet()) {
                String fieldName = yearToFieldName.get(year);
                if (fieldName != null) {
                    acc.put(fieldName, yearToIncome.get(year));
                }
            }
        }
    }
}
