trigger UpdateCustomerDiscount on Account (before insert, before update) {
    // Указываем нужный RecordTypeId
    String targetRecordTypeId = '012Kc000000tenBIAQ';

    for (Account acc : Trigger.new) {
        // Проверяем RecordTypeId
        if (acc.RecordTypeId == targetRecordTypeId) {
            String clientType = acc.Client_Type__c;

            if (clientType != null && clientType.contains('Discount')) {
                try {
                    // Извлекаем процент скидки с помощью регулярного выражения
                    Pattern discountPattern = Pattern.compile('(\\d+)%');
                    Matcher matcher = discountPattern.matcher(clientType);

                    if (matcher.find()) {
                        // Записываем процент в поле скидки
                        acc.Customer_Discount_Ammount__c = Decimal.valueOf(matcher.group(1));
                    } else {
                        // Если процент не найден, записываем 0
                        acc.Customer_Discount_Ammount__c = 0;
                    }
                } catch (Exception e) {
                    System.debug('Ошибка при парсинге Client_Type__c: ' + e.getMessage());
                    acc.Customer_Discount_Ammount__c = 0;
                }
            } else {
                // Если поле не содержит скидки, записываем 0
                acc.Customer_Discount_Ammount__c = 0;
            }
        }
    }
}
