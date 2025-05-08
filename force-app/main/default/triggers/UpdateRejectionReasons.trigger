trigger UpdateRejectionReasons on Lead (after insert, after update) {

    List<RejectionReason__c> reasonsToInsert = new List<RejectionReason__c>();
    Set<Id> leadIds = new Set<Id>();

    // Константа RecordTypeId
    String requiredRecordTypeId = '012Kc000000tenuIAA';

    // Сопоставление причин отказа с полями объекта RejectionReason__c
    Map<String, String> reasonFields = new Map<String, String>{
        'Avg Monthly Revenue' => 'Avg_Monthly_Revenue__c',
        'Min Single Month Revenue' => 'Min_Single_Month_Revenue__c',
        'Inconsistent revenue' => 'Inconsistent_Revenue__c',
        'Min Monthly Deposit Count' => 'Min_Monthly_Deposit_Count__c',
        'Max Existing MCA Positions' => 'Max_Existing_MCA_Positions__c',
        'Negative Balance Days Last Month' => 'Negative_Balance_Days_Last_Month__c',
        'Low Balance Days (including neg days) Last month' => 'Low_Balance_Days_Including_Neg_Days_La__c',
        'Max Leverage' => 'Max_Leverage__c',
        'Avg Monthly Rev for Trucking & Construction' => 'Avg_Monthly_Rev_For_Trucking_Construc__c',
        'Min Single Month Rev for Trucking & Construction' => 'Min_Single_Month_Rev_For_Trucking_Cons__c',
        'Adjusted Payments' => 'Adjusted_Payments__c',
        'Paying Collections Company' => 'Paying_Collections_Company__c',
        'Stopped Payment (on MCA company)' => 'Stopped_Payment_On_MCA_Company__c',
        'Max MCA Payment Bounces (daily)' => 'Max_MCA_Payment_Bounces_Daily__c',
        'Max MCA Payment Bounces (weekly)' => 'Max_MCA_Payment_Bounces_Weekly__c',
        'Must be Business/Commercial Checking Account' => 'Must_Be_Business_Commercial_Checking_Acc__c',
        'Unacceptable Banks' => 'Unacceptable_Banks__c',
        'NSF charge / Overdraft' => 'NSF_Charge_Overdraft__c',
        'Reverse payment' => 'Reverse_Payment__c',
        'Negative Balance Days (per month)' => 'Negative_Balance_Days_Per_Month__c'
    };

    // Сбор ID обновленных лидов
    for (Lead l : Trigger.new) {
        if (l.RecordTypeId == requiredRecordTypeId) {
            leadIds.add(l.Id);
        }
    }

    // Удаляем старые записи причин отказа для нужного RecordTypeId
    if (!leadIds.isEmpty()) {
        delete [SELECT Id FROM RejectionReason__c WHERE Lead__c IN :leadIds];
    }

    // Обрабатываем каждый лид из триггера
    for (Lead l : Trigger.new) {
        if (l.RecordTypeId == requiredRecordTypeId) {
            RejectionReason__c reasonRecord = new RejectionReason__c(
                Lead__c = l.Id,
                Broker_email__c = l.Broker_email__c
            );

            // Разделяем и устанавливаем причины из поля ClosingReasonNew__c
            if (l.ClosingReasonNew__c != null) {
                List<String> reasons = l.ClosingReasonNew__c.split(';');
                RejectionReasonHelper.setReasonValues(reasons, reasonRecord, reasonFields);
            }

            // Разделяем и устанавливаем причины из поля ClosingReasonFirstNew__c
            if (l.ClosingReasonFirstNew__c != null) {
                List<String> reasonsFirst = l.ClosingReasonFirstNew__c.split(';');
                RejectionReasonHelper.setReasonValues(reasonsFirst, reasonRecord, reasonFields);
            }

            // Добавляем запись в список, если хотя бы одна причина установлена
            reasonsToInsert.add(reasonRecord);
        }
    }

    // Вставляем новые записи причин отказа
    if (!reasonsToInsert.isEmpty()) {
        insert reasonsToInsert;
    }
}
