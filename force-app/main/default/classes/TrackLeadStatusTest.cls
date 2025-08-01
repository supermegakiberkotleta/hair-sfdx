@isTest
public class TrackLeadStatusTest {
    @isTest
    static void testStatusHistoryOnInsertAndUpdate() {
        // Создаём нового лида
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Status = 'New'
        );
        insert lead;

        // Получаем записи истории — должна быть одна запись после вставки
        List<Lead_Status_History__c> historyAfterInsert = [
            SELECT Id, Status__c
            FROM Lead_Status_History__c
            WHERE Lead__c = :lead.Id
        ];

        // Обновляем статус
        lead.Status = 'Working';
        update lead;

        // После изменения статуса — должно быть 2 записи
        List<Lead_Status_History__c> historyAfterUpdate = [
            SELECT Id, Status__c
            FROM Lead_Status_History__c
            WHERE Lead__c = :lead.Id
            ORDER BY Date__c
        ];

        // Пробуем обновить тот же статус ещё раз — запись не должна добавиться
        lead.Status = 'Working';
        update lead;

        List<Lead_Status_History__c> historyAfterNoChange = [
            SELECT Id
            FROM Lead_Status_History__c
            WHERE Lead__c = :lead.Id
        ];

        List<Lead_Status_History__c> history = [
            SELECT Status__c, Is_First_History__c, Date__c
            FROM Lead_Status_History__c
            WHERE Lead__c = :lead.Id
            ORDER BY Date__c
        ];

    }
}