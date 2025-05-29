trigger UpdateLeadTags on Lead (after insert, after update) {
    List<Tag__c> tagsToInsert = new List<Tag__c>();
    Set<Id> leadIds = new Set<Id>();

    String requiredRecordTypeId = '012Kc000000tenuIAA';

    Map<String, String> tagFieldMap = new Map<String, String>{
        'Biz Capital 10%'    => 'biz_capital_10__c',
        'Biz Capital 8%'     => 'biz_capital_8__c',
        'Biz Capital 6%'     => 'biz_capital_6__c',
        'Boostra 12%'        => 'boostra_12__c',
        'Boostra High Risk'  => 'boostra_high_risk__c',
        'No MCA'             => 'no_mca__c',
        'Denied'             => 'denied__c'
    };

    for (Lead l : Trigger.new) {
        
        if (l.RecordTypeId != requiredRecordTypeId) {
            continue;
        }

        Boolean tagChanged = true;
        if (Trigger.isUpdate) {
            Lead oldLead = Trigger.oldMap.get(l.Id);
            tagChanged = l.Tag__c != oldLead.Tag__c;
        }

        if (tagChanged) {
            leadIds.add(l.Id);
        } else {
        }
    }

    if (!leadIds.isEmpty()) {
        List<Tag__c> oldTags = [SELECT Id FROM Tag__c WHERE Lead__c IN :leadIds];
        delete oldTags;
    }

    for (Lead l : Trigger.new) {
        if (l.RecordTypeId != requiredRecordTypeId) continue;

        Boolean tagChanged = true;
        if (Trigger.isUpdate) {
            Lead oldLead = Trigger.oldMap.get(l.Id);
            tagChanged = l.Tag__c != oldLead.Tag__c;
        }

        if (!tagChanged) continue;

        Tag__c tagRecord = new Tag__c(
            Lead__c = l.Id,
            Broker_email__c = l.Broker_email__c
        );

        if (l.Tag__c != null && tagFieldMap.containsKey(l.Tag__c)) {
            String tagField = tagFieldMap.get(l.Tag__c);
            tagRecord.put(tagField, true);
        } else {
            tagRecord.none__c = true;
        }

        tagsToInsert.add(tagRecord);
    }

    if (!tagsToInsert.isEmpty()) {
        insert tagsToInsert;
    } else {
    }

}
