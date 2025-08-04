public with sharing class InstagramChatController {

    @AuraEnabled(cacheable=true)
    public static String getLeadName (String objectApiName, Id recordId) {
        SObject sObj;

        if (objectApiName == 'Lead') {
            sObj = [SELECT Name FROM Lead WHERE Id = :recordId LIMIT 1];
        } else if (objectApiName == 'Contact') {
            sObj = [SELECT Name FROM Contact WHERE Id = :recordId LIMIT 1];
        } else if (objectApiName == 'Account') {
            sObj = [SELECT Name FROM Account WHERE Id = :recordId LIMIT 1];
        } else if (objectApiName == 'Opportunity') {
            sObj = [SELECT Name FROM Opportunity WHERE Id = :recordId LIMIT 1];
        } else {
            throw new AuraHandledException('Unsupported object: ' + objectApiName);
        }

        return (String)sObj.get('Name');
    }

    @AuraEnabled(cacheable=true)
    public static String getRecordPsid(String objectApiName, Id recordId) {
        if (objectApiName == 'Lead') {
            return [SELECT Instagram_PSID__c FROM Lead WHERE Id = :recordId LIMIT 1].Instagram_PSID__c;
        }
        if (objectApiName == 'Contact') {
            return [SELECT Instagram_PSID__c FROM Contact WHERE Id = :recordId LIMIT 1].Instagram_PSID__c;
        }
        if (objectApiName == 'Account') {
            return [SELECT Instagram_PSID__c FROM Account WHERE Id = :recordId LIMIT 1].Instagram_PSID__c;
        }
        if (objectApiName == 'Opportunity') {
            return [SELECT Instagram_PSID__c FROM Opportunity WHERE Id = :recordId LIMIT 1].Instagram_PSID__c;
        }

        throw new AuraHandledException('Unsupported object: ' + objectApiName);
    }
}