public with sharing class ChatNotificationHelper {
    @AuraEnabled(cacheable=true)
    public static String getRecordName(Id recordId) {
        try {
            if (recordId.getSObjectType() == Lead.SObjectType) {
                Lead lead = [SELECT LastName FROM Lead WHERE Id = :recordId LIMIT 1];
                return lead.LastName;
            } else if (recordId.getSObjectType() == Contact.SObjectType) {
                Contact contact = [SELECT LastName FROM Contact WHERE Id = :recordId LIMIT 1];
                return contact.LastName;
            } else if (recordId.getSObjectType() == Account.SObjectType) {
                Account account = [SELECT Name FROM Account WHERE Id = :recordId LIMIT 1];
                return account.Name;
            }
        } catch (Exception e) {
            return 'Error getting name';
        }
        return 'Unknown';
    }
}