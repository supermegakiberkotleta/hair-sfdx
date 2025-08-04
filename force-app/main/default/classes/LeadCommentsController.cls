public with sharing class LeadCommentsController {
    @AuraEnabled
    public static void addComment(Id parentId, String commentText) {
        try {
            // Проверяем входные параметры
            if (String.isBlank(commentText)) {
                throw new AuraHandledException('Комментарий не может быть пустым');
            }
            
            if (parentId == null) {
                throw new AuraHandledException('ID записи не может быть пустым');
            }
            
            // Проверяем существование записи
            List<Lead> leads = [SELECT Id FROM Lead WHERE Id = :parentId];
            if (leads.isEmpty()) {
                throw new AuraHandledException('Запись не найдена');
            }
            
            // Создаем ContentNote
            ContentNote note = new ContentNote();
            note.Title = 'Comment ' + System.now();
            note.Content = Blob.valueOf(commentText);
            
            try {
                insert note;
            } catch (DmlException e) {
                throw new AuraHandledException('Ошибка при создании комментария: ' + e.getMessage());
            }

            // Создаем связь с лидом
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = note.Id;
            cdl.LinkedEntityId = parentId;
            cdl.ShareType = 'V'; // V = Viewer
            
            try {
                insert cdl;
            } catch (DmlException e) {
                // Удаляем созданную заметку, если не удалось создать связь
                delete note;
                throw new AuraHandledException('Ошибка при связывании комментария с записью: ' + e.getMessage());
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<CommentWrapper> getComments(Id parentId) {
        try {
            // Проверяем входной параметр
            if (parentId == null) {
                throw new AuraHandledException('ID записи не может быть пустым');
            }
            
            // Проверяем существование записи
            List<Lead> leads = [SELECT Id FROM Lead WHERE Id = :parentId];
            if (leads.isEmpty()) {
                throw new AuraHandledException('Запись не найдена');
            }
            
            List<CommentWrapper> comments = new List<CommentWrapper>();
            
            // Получаем все связанные ContentNote через ContentDocumentLink
            List<ContentDocumentLink> links = [
                SELECT ContentDocument.Title, ContentDocument.CreatedDate, 
                       ContentDocument.CreatedBy.Name, ContentDocument.LatestPublishedVersion.VersionData 
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :parentId 
                AND ContentDocument.FileType = 'SNOTE'
                ORDER BY ContentDocument.CreatedDate DESC
                LIMIT 100
            ];
            
            for(ContentDocumentLink link : links) {
                if (link.ContentDocument.LatestPublishedVersion != null) {
                    String content = link.ContentDocument.LatestPublishedVersion.VersionData.toString();
                    comments.add(new CommentWrapper(
                        link.ContentDocument.Id,
                        content,
                        link.ContentDocument.CreatedDate,
                        link.ContentDocument.CreatedBy.Name
                    ));
                }
            }
            
            return comments;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class CommentWrapper {
        @AuraEnabled public String id;
        @AuraEnabled public String body;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String createdByName;
        
        public CommentWrapper(String id, String body, Datetime createdDate, String createdByName) {
            this.id = id;
            this.body = body;
            this.createdDate = createdDate;
            this.createdByName = createdByName;
        }
    }
}