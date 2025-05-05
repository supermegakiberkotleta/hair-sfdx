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
        System.assertEquals(1, historyAfterInsert.size(), 'После вставки должна быть 1 запись в истории');
        System.assertEquals('New', historyAfterInsert[0].Status__c);

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
        System.assertEquals(2, historyAfterUpdate.size(), 'После изменения статуса должно быть 2 записи');
        System.assertEquals('New', historyAfterUpdate[0].Status__c);
        System.assertEquals('Working', historyAfterUpdate[1].Status__c);

        // Пробуем обновить тот же статус ещё раз — запись не должна добавиться
        lead.Status = 'Working';
        update lead;

        List<Lead_Status_History__c> historyAfterNoChange = [
            SELECT Id
            FROM Lead_Status_History__c
            WHERE Lead__c = :lead.Id
        ];
        System.assertEquals(2, historyAfterNoChange.size(), 'Если статус не поменялся, история не должна расти');

        List<Lead_Status_History__c> history = [
            SELECT Status__c, Is_First_History__c, Date__c
            FROM Lead_Status_History__c
            WHERE Lead__c = :lead.Id
            ORDER BY Date__c
        ];

        System.assertEquals(true, history[0].Is_First_History__c, 'Первая запись должна быть помечена как первая');
        System.assertEquals(false, history[1].Is_First_History__c, 'Вторая запись не должна быть помечена как первая');

    }
}
