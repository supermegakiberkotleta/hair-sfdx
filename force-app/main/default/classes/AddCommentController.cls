public without sharing class AddCommentController {
    @AuraEnabled
    public static void saveComment(String leadId, String comment) {
        if (String.isBlank(leadId) || String.isBlank(comment)) {
            throw new AuraHandledException('ID лида или комментарий не могут быть пустыми');
        }
        
        ConnectApi.MessageBodyInput msgBody = new ConnectApi.MessageBodyInput();
        msgBody.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
        textSegment.text = comment;
        msgBody.messageSegments.add(textSegment);
        
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        feedItemInput.body = msgBody;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = leadId;
        
        try {
            ConnectApi.ChatterFeeds.postFeedItem(null, ConnectApi.FeedType.News, leadId, feedItemInput, null);
        } catch (Exception ex) {
            throw new AuraHandledException('Ошибка при сохранении комментария: ' + ex.getMessage());
        }
    }
}