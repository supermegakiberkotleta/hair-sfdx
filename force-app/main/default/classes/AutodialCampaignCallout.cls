public with sharing class AutodialCampaignCallout {

    public class CreateJob implements Queueable, Database.AllowsCallouts {
        private Set<Id> recordIds;

        public CreateJob(Set<Id> recordIds) {
            this.recordIds = recordIds;
        }

        public void execute(QueueableContext context) {
            // Build a dynamic SOQL selecting all accessible fields to avoid field access exceptions
            List<String> fieldApiNames = new List<String>();
            Map<String, Schema.SObjectField> fieldMap = Autodial_Campaign__c.SObjectType.getDescribe().fields.getMap();
            for (String apiName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fDesc = fieldMap.get(apiName).getDescribe();
                if (fDesc.isAccessible()) {
                    fieldApiNames.add(apiName);
                }
            }

            String soql = 'SELECT ' + String.join(fieldApiNames, ',') + ' FROM Autodial_Campaign__c WHERE Id IN :recordIds';
            List<Autodial_Campaign__c> records = Database.query(soql);

            for (Autodial_Campaign__c rec : records) {
                Map<String, Object> payload = AutodialCampaignCallout.buildAllFieldsPayload(rec);
                AutodialCampaignCallout.performPost('/api/v1/autodial-campaign/create', payload);
            }
        }
    }

    public class UpdateJob implements Queueable, Database.AllowsCallouts {
        private Id recordId;
        private Map<String, Object> changedFields;

        public UpdateJob(Id recordId, Map<String, Object> changedFields) {
            this.recordId = recordId;
            this.changedFields = changedFields == null ? new Map<String, Object>() : new Map<String, Object>(changedFields);
        }

        public void execute(QueueableContext context) {
            // Always include Id in the payload
            changedFields.put('Id', recordId);
            AutodialCampaignCallout.performPost('/api/v1/autodial-campaign/update', changedFields);
        }
    }

    public class DeleteJob implements Queueable, Database.AllowsCallouts {
        private Set<Id> recordIds;

        public DeleteJob(Set<Id> recordIds) {
            this.recordIds = recordIds;
        }

        public void execute(QueueableContext context) {
            if (recordIds == null || recordIds.isEmpty()) return;
            for (Id recId : recordIds) {
                Map<String, Object> payload = new Map<String, Object>{ 'Id' => recId };
                AutodialCampaignCallout.performPost('/api/v1/autodial-campaign/delete', payload);
            }
        }
    }

    public static void enqueueCreate(List<Autodial_Campaign__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) return;
        System.enqueueJob(new CreateJob(new Map<Id, Autodial_Campaign__c>(newRecords).keySet()));
    }

    public static void enqueueUpdate(Map<Id, Autodial_Campaign__c> oldMap, Map<Id, Autodial_Campaign__c> newMap) {
        if (newMap == null || newMap.isEmpty()) return;
        for (Id recId : newMap.keySet()) {
            Autodial_Campaign__c oldRec = oldMap != null ? oldMap.get(recId) : null;
            Autodial_Campaign__c newRec = newMap.get(recId);
            Map<String, Object> changed = buildChangedFieldsPayload(oldRec, newRec);
            if (!changed.isEmpty()) {
                System.enqueueJob(new UpdateJob(recId, changed));
            }
        }
    }

    public static void enqueueDelete(List<Autodial_Campaign__c> oldRecords) {
        if (oldRecords == null || oldRecords.isEmpty()) return;
        System.enqueueJob(new DeleteJob(new Map<Id, Autodial_Campaign__c>(oldRecords).keySet()));
    }

    private static void performPost(String relativePath, Map<String, Object> payload) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        String base = 'callout:Telephony_Credential';
        String path = (relativePath != null && relativePath.startsWith('/')) ? relativePath : ('/' + String.valueOf(relativePath));
        req.setEndpoint(base + path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(payload));
        try {
            http.send(req);
        } catch (Exception e) {
            // Swallow to avoid failing DML context; consider adding logging if available
        }
    }

    public static Map<String, Object> buildAllFieldsPayload(SObject sobj) {
        Map<String, Object> payload = new Map<String, Object>();
        if (sobj == null) return payload;

        // Only include fields that are actually populated on this SObject instance
        // to avoid SObjectExceptions for non-queried fields.
        Map<String, Object> populated = sobj.getPopulatedFieldsAsMap();
        if (populated != null && !populated.isEmpty()) {
            payload.putAll(populated);
        }
        return payload;
    }

    public static Map<String, Object> buildChangedFieldsPayload(SObject oldRec, SObject newRec) {
        Map<String, Object> changed = new Map<String, Object>();
        if (newRec == null) return changed;

        Map<String, Object> newMap = newRec.getPopulatedFieldsAsMap();
        Map<String, Object> oldMap = oldRec == null ? new Map<String, Object>() : oldRec.getPopulatedFieldsAsMap();

        Set<String> fieldNames = new Set<String>();
        if (newMap != null) fieldNames.addAll(newMap.keySet());
        if (oldMap != null) fieldNames.addAll(oldMap.keySet());

        // Skip system audit fields that frequently change automatically if desired
        fieldNames.remove('LastModifiedDate');
        fieldNames.remove('LastModifiedById');
        fieldNames.remove('SystemModstamp');

        for (String fieldName : fieldNames) {
            Object newVal = newMap == null ? null : newMap.get(fieldName);
            Object oldVal = oldMap == null ? null : oldMap.get(fieldName);
            if (!areEqual(oldVal, newVal)) {
                changed.put(fieldName, newVal);
            }
        }
        return changed;
    }

    private static Boolean areEqual(Object a, Object b) {
        if (a == null && b == null) return true;
        if (a == null || b == null) return false;
        return String.valueOf(a) == String.valueOf(b);
    }
}


