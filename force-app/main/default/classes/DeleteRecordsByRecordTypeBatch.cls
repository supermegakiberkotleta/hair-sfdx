public class DeleteRecordsByRecordTypeBatch implements Database.Batchable<SObject> {

    private String sObjectType;
    private String recordTypeId;

    public DeleteRecordsByRecordTypeBatch(String sObjectType, String recordTypeId) {
        this.sObjectType = sObjectType;
        this.recordTypeId = recordTypeId;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id FROM ' + sObjectType + ' WHERE RecordTypeId = :recordTypeId';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            delete scope;
        } catch (DmlException e) {
            // Можно логировать ошибки или использовать Database.delete(scope, false)
            System.debug('Ошибка при удалении: ' + e.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Завершено удаление записей из ' + sObjectType);
    }
}