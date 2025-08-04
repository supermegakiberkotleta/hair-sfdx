global class BrokerFeeBatch implements Database.Batchable<SObject> {
    private String sObjectType;

    global BrokerFeeBatch(String sObjectType) {
        this.sObjectType = sObjectType;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Tag__c, OfferAmount__c, BrokersFee__c FROM ' + sObjectType +
                       ' WHERE OfferAmount__c != null AND Tag__c != null';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<SObject> toUpdate = new List<SObject>();

        for (SObject record : scope) {
            String tag = String.valueOf(record.get('Tag__c'));
            Decimal offer = (Decimal) record.get('OfferAmount__c');
            Decimal fee = BrokerFeeCalculator.calculate(tag, offer);

            if (fee != null) {
                record.put('BrokersFee__c', fee);
                toUpdate.add(record);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optionally log or notify
    }
}