@IsTest
private class ApiLeadStageControllerTest {

    @IsTest
    static void testReportAverages_basic() {
        // Входные параметры
        String dateStart = '2025-01-01';
        String dateFinish = '2025-01-10';

        // Предсоздадим "старую" запись отчёта, чтобы проверить, что её удалят
        insert new API_Lead_Stage__c(Column_1__c = 'legacy');

        // Базовые точки во времени для детерминированных длительностей
        // ВАЖНО: последний статус поставим "OTHER", чтобы интервал до System.now()
        // не попадал в агрегацию (его нет в целевом списке статусов).
        Datetime t0 = Datetime.newInstance(2025, 1, 5, 10, 0, 0); // попадает в интервал
        Datetime t0_plus_60  = t0.addMinutes(60);
        Datetime t0_plus_120 = t0.addMinutes(120);
        Datetime t0_plus_180 = t0.addMinutes(180);

        Datetime t1 = Datetime.newInstance(2024, 12, 20, 12, 0, 0); // вне интервала
        Datetime t1_plus_60  = t1.addMinutes(60);
        Datetime t1_plus_120 = t1.addMinutes(120);

        // Лид #1 — войдёт в отчёт
        Lead lead1 = new Lead(
            LastName = 'L1',
            Company = 'C1'
        );
        // Лид #2 — войдёт в отчёт
        Lead lead2 = new Lead(
            LastName = 'L2',
            Company = 'C2'
        );
        // Лид #3 — НЕ войдёт (NEW APPLICATION вне интервала)
        Lead lead3 = new Lead(
            LastName = 'L3',
            Company = 'C3'
        );
        insert new List<Lead>{ lead1, lead2, lead3 };

        // История для lead1:
        // NEW APPLICATION (120 мин) -> RISK ANALYSIS (60 мин) -> OTHER (до now, игнор)
        List<Lead_Status_History__c> hist = new List<Lead_Status_History__c>{
            new Lead_Status_History__c(Lead__c = lead1.Id, Status__c = 'NEW APPLICATION', Date__c = t0),
            new Lead_Status_History__c(Lead__c = lead1.Id, Status__c = 'RISK ANALYSIS', Date__c = t0_plus_120),
            new Lead_Status_History__c(Lead__c = lead1.Id, Status__c = 'OTHER', Date__c = t0_plus_180)
        };

        // История для lead2:
        // NEW APPLICATION (60 мин) -> RISK ANALYSIS (60 мин) -> OTHER (до now, игнор)
        hist.add(new Lead_Status_History__c(Lead__c = lead2.Id, Status__c = 'NEW APPLICATION', Date__c = t0));
        hist.add(new Lead_Status_History__c(Lead__c = lead2.Id, Status__c = 'RISK ANALYSIS', Date__c = t0_plus_60));
        hist.add(new Lead_Status_History__c(Lead__c = lead2.Id, Status__c = 'OTHER', Date__c = t0_plus_120));

        // История для lead3 (вне интервала — не должен учитываться)
        hist.add(new Lead_Status_History__c(Lead__c = lead3.Id, Status__c = 'NEW APPLICATION', Date__c = t1));
        hist.add(new Lead_Status_History__c(Lead__c = lead3.Id, Status__c = 'RISK ANALYSIS', Date__c = t1_plus_60));
        hist.add(new Lead_Status_History__c(Lead__c = lead3.Id, Status__c = 'OTHER', Date__c = t1_plus_120));

        insert hist;

        Test.startTest();
        ApiLeadStageController.updateLeadStageReport(dateStart, dateFinish);
        Test.stopTest(); // дождёмся выполнения @future

        // Проверяем, что осталась ровно одна свежая запись отчёта
        List<API_Lead_Stage__c> rows = [
            SELECT Id,
                   Column_1__c,  // NEW APPLICATION
                   Column_2__c,  // RISK ANALYSIS
                   Column_3__c,  // STOP-FACTORS CHECK
                   Column_4__c,  // APPROVED
                   Column_5__c,  // DENIED
                   Column_6__c,  // MANUAL PARSING
                   Column_7__c,  // Final Denied
                   Column_8__c,  // Offer sent to broker
                   Column_9__c,  // Offer sent to broker manual
                   Column_10__c, // Offer Accepted
                   Column_11__c, // Agreement sent
                   Column_12__c, // Agreement signed
                   Column_13__c, // Funding call
                   Column_14__c, // final check Mary
                   Column_15__c, // Final check Violetta
                   Column_16__c, // To pay
                   Column_17__c, // Call after
                   Column_18__c  // Closed Lost
            FROM API_Lead_Stage__c
        ];
        System.assertEquals(1, rows.size(), 'Должна быть одна строка отчёта');

        API_Lead_Stage__c r = rows[0];

        // Ожидаемые средние:
        // NEW APPLICATION: (120 + 60) / 2 = 90 мин -> 1:30
        // RISK ANALYSIS:   ( 60 + 60) / 2 = 60 мин -> 1:00
        System.assertEquals('1:30', r.Column_1__c, 'Среднее для NEW APPLICATION неверно');
        System.assertEquals('1:00', r.Column_2__c, 'Среднее для RISK ANALYSIS неверно');

        // Остальные статусы не встречались -> 0:00
        System.assertEquals('0:00', r.Column_3__c);
        System.assertEquals('0:00', r.Column_4__c);
        System.assertEquals('0:00', r.Column_5__c);
        System.assertEquals('0:00', r.Column_6__c);
        System.assertEquals('0:00', r.Column_7__c);
        System.assertEquals('0:00', r.Column_8__c);
        System.assertEquals('0:00', r.Column_9__c);
        System.assertEquals('0:00', r.Column_10__c);
        System.assertEquals('0:00', r.Column_11__c);
        System.assertEquals('0:00', r.Column_12__c);
        System.assertEquals('0:00', r.Column_13__c);
        System.assertEquals('0:00', r.Column_14__c);
        System.assertEquals('0:00', r.Column_15__c);
        System.assertEquals('0:00', r.Column_16__c);
        System.assertEquals('0:00', r.Column_17__c);
        System.assertEquals('0:00', r.Column_18__c);
    }

    @IsTest
    static void testNoMatchingLeads_createsZeroRow() {
        // Пустые данные: ни лидов, ни истории
        String dateStart = '2025-01-01';
        String dateFinish = '2025-01-10';

        Test.startTest();
        ApiLeadStageController.updateLeadStageReport(dateStart, dateFinish);
        Test.stopTest();

        List<API_Lead_Stage__c> rows = [
            SELECT Column_1__c, Column_2__c, Column_3__c, Column_4__c, Column_5__c,
                   Column_6__c, Column_7__c, Column_8__c, Column_9__c, Column_10__c,
                   Column_11__c, Column_12__c, Column_13__c, Column_14__c, Column_15__c,
                   Column_16__c, Column_17__c, Column_18__c
            FROM API_Lead_Stage__c
        ];
        System.assertEquals(1, rows.size(), 'Должна создаться одна строка отчёта даже без данных');

        for (Integer i = 1; i <= 18; i++) {
            String fieldName = 'Column_' + String.valueOf(i) + '__c';
            String val = (String)rows[0].get(fieldName);
            System.assertEquals('0:00', val, 'Ожидаем 0:00 в ' + fieldName);
        }
    }
}