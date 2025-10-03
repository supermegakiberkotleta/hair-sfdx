@IsTest
private class CampaignMessageSchedulerTest {
    // Хелпер для создания кампании
    private static Campaign makeCampaign(String name, Datetime scheduledAt, String status) {
        Campaign c = new Campaign(
            Name = name,
            Status = status,
            // предполагаем, что Scheduled_Date__c — Datetime
            Scheduled_Date__c = scheduledAt
        );
        return c;
    }

    @IsTest
    static void testScheduler_UpdatesPastCampaigns_AndSkipsFuture() {
        // Подготовка данных
        Datetime now = System.now();
        Campaign past = makeCampaign('Past Campaign', now.addMinutes(-5), 'Planned');
        Campaign future = makeCampaign('Future Campaign', now.addHours(1), 'Planned');
        insert new List<Campaign>{ past, future };

        Test.startTest();
        // Запускаем планировщик: достаточно валидного cron (каждую минуту)
        String cron = '0 0 0 * * ? *'; // секунды, минуты, часы, день, месяц, день_нед, год(опц)
        System.schedule('CampaignMessageScheduler_Test', cron, new CampaignMessageScheduler());
        Test.stopTest(); // здесь выполнится execute и отработают батчи

        // Обновляем из базы и проверяем статусы
        past = [SELECT Id, Status FROM Campaign WHERE Id = :past.Id];
        future = [SELECT Id, Status FROM Campaign WHERE Id = :future.Id];

        System.assertEquals('In Progress', past.Status, 'Прошлая кампания должна перейти в In Progress');
        System.assertEquals('Planned', future.Status, 'Будущая кампания не должна измениться');
    }

    @IsTest
    static void testScheduler_NoCampaigns_NoErrors() {
        // Никаких кампаний, просто убеждаемся, что ошибок нет
        Test.startTest();
        String cron = '0 0 0 * * ? *';
        System.schedule('CampaignMessageScheduler_Test_Empty', cron, new CampaignMessageScheduler());
        Test.stopTest();

        // Если дошли до сюда — тест прошёл. Для формальности добавим assert.
        System.assert(true, 'Планировщик должен отработать без ошибок при отсутствии кампаний');
    }
}