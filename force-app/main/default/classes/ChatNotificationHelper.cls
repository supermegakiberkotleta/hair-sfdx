public with sharing class ChatNotificationHelper {
    @AuraEnabled(cacheable=false)
    public static String getRecordName(Id recordId) {
        try {
            if (recordId.getSObjectType() == Lead.SObjectType) {
                List<Lead> leads = [SELECT LastName, LeadSource FROM Lead WHERE Id = :recordId LIMIT 1];
                if (leads.isEmpty()) {
                    return 'Lead deleted';
                }
                Lead lead = leads[0];
                String name = String.isBlank(lead.LastName) ? 'Unknown' : lead.LastName;
                String source = String.isBlank(lead.LeadSource) ? 'Unknown' : lead.LeadSource;
                return name + ' | ' + source;
            } else if (recordId.getSObjectType() == Contact.SObjectType) {
                List<Contact> contacts = [SELECT LastName, LeadSource FROM Contact WHERE Id = :recordId LIMIT 1];
                if (contacts.isEmpty()) {
                    return 'Contact deleted';
                }
                Contact contact = contacts[0];
                String name = String.isBlank(contact.LastName) ? 'Unknown' : contact.LastName;
                String source = String.isBlank(contact.LeadSource) ? 'Unknown' : contact.LeadSource;
                return name + ' | ' + source;
            } else if (recordId.getSObjectType() == Account.SObjectType) {
                List<Account> accounts = [SELECT Name, AccountSource FROM Account WHERE Id = :recordId LIMIT 1];
                if (accounts.isEmpty()) {
                    return 'Account deleted';
                }
                Account account = accounts[0];
                String name = String.isBlank(account.Name) ? 'Unknown' : account.Name;
                String source = String.isBlank(account.AccountSource) ? 'Unknown' : account.AccountSource;
                return name + ' | ' + source;
            }
        } catch (Exception e) {
            System.debug('Error getting record name: ' + e.getMessage());
            return 'Error getting name';
        }
        return 'Unknown';
    }
}