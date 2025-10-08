public with sharing class EmailMessagesController {
    @AuraEnabled(cacheable=true)
    public static List<EmailMessage> getMessages() {
        return [
            SELECT Id, Subject, FromAddress, ToAddress, TextBody, CreatedDate, RelatedToId
            FROM EmailMessage
            WHERE RelatedToId IN (SELECT Id FROM Opportunity)
            ORDER BY CreatedDate DESC
            LIMIT 1000
        ];
    }
}