global class LeadDuplicateCleanerBatch implements Database.Batchable<SObject>, Database.Stateful {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, WhatsApp_ID__c, Instagram_PSID__c, Facebook_PSID__c, Status, LastModifiedDate,
                   (SELECT Id FROM Tasks)
            FROM Lead
            WHERE (WhatsApp_ID__c != null OR Instagram_PSID__c != null OR Facebook_PSID__c != null)
            AND RecordTypeId = '012Kc000000ten6IAA'
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Lead> leads) {
        Map<String, List<Lead>> mapByWhatsApp = new Map<String, List<Lead>>();
        Map<String, List<Lead>> mapByInstagram = new Map<String, List<Lead>>();
        Map<String, List<Lead>> mapByFacebook = new Map<String, List<Lead>>();

        for (Lead l : leads) {
            if (l.WhatsApp_ID__c != null) {
                if (!mapByWhatsApp.containsKey(l.WhatsApp_ID__c)) mapByWhatsApp.put(l.WhatsApp_ID__c, new List<Lead>());
                mapByWhatsApp.get(l.WhatsApp_ID__c).add(l);
            }

            if (l.Instagram_PSID__c != null) {
                if (!mapByInstagram.containsKey(l.Instagram_PSID__c)) mapByInstagram.put(l.Instagram_PSID__c, new List<Lead>());
                mapByInstagram.get(l.Instagram_PSID__c).add(l);
            }

            if (l.Facebook_PSID__c != null) {
                if (!mapByFacebook.containsKey(l.Facebook_PSID__c)) mapByFacebook.put(l.Facebook_PSID__c, new List<Lead>());
                mapByFacebook.get(l.Facebook_PSID__c).add(l);
            }
        }

        List<Lead> toDelete = new List<Lead>();
        Set<Id> alreadyMarked = new Set<Id>();

        deleteDuplicates(mapByWhatsApp, toDelete, alreadyMarked);
        deleteDuplicates(mapByInstagram, toDelete, alreadyMarked);
        deleteDuplicates(mapByFacebook, toDelete, alreadyMarked);

        if (!toDelete.isEmpty()) {
            delete toDelete;
        }
    }

    private void deleteDuplicates(Map<String, List<Lead>> groupedLeads, List<Lead> toDelete, Set<Id> alreadyMarked) {
        for (List<Lead> leadGroup : groupedLeads.values()) {
            if (leadGroup.size() < 2) continue;

            leadGroup.sort(new LeadDuplicateComparator());

            for (Integer i = 1; i < leadGroup.size(); i++) {
                Lead l = leadGroup[i];
                if (!alreadyMarked.contains(l.Id)) {
                    toDelete.add(l);
                    alreadyMarked.add(l.Id);
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        // логика при завершении
    }

    public class LeadDuplicateComparator implements Comparator<Lead> {
        public Integer compare(Lead a, Lead b) {
            Boolean aClosed = a.Status == 'Closed Lost';
            Boolean bClosed = b.Status == 'Closed Lost';
            if (aClosed != bClosed) return aClosed ? 1 : -1;

            Boolean aHasTasks = a.Tasks != null && !a.Tasks.isEmpty();
            Boolean bHasTasks = b.Tasks != null && !b.Tasks.isEmpty();
            if (aHasTasks != bHasTasks) return aHasTasks ? -1 : 1;

            if (a.LastModifiedDate > b.LastModifiedDate) return -1;
            if (a.LastModifiedDate < b.LastModifiedDate) return 1;
            return 0;
        }
    }
}
