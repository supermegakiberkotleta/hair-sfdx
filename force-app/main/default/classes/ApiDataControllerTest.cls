@IsTest
private class ApiDataControllerTest {

    // --- Мок успешного ответа (200) ---
    private class MockHttp200 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod(), 'Ожидался POST');
            System.assert(
                req.getEndpoint().contains('https://lenderpro.ai/api/v1/report/us-report-sf'),
                'Неверный endpoint: ' + req.getEndpoint()
            );

            // Формируем 2 "группы", в каждой по 2 "таблицы".
            // Таблица = список строк, где [0] — заголовки, дальше — данные.
            // tableIndex == 0 -> Row_Type = 'SUM', tableIndex == 1 -> 'PERCENT'
            // Глобальная нумерация таблиц: 0,1,2,3
            // Из глобальных №2 и №3 (т.е. group1.table0 и group1.table1) — пишем во второй объект.
            String jsonBody =
            '[ ' +
            '  [ ' +
            '    [ ' +
            '      ["Col1","Col2","Col3"], ' +     // group0.table0 -> SUM
            '      ["RowA","10","20"], ' +
            '      ["RowB","30","40"] ' +
            '    ], ' +
            '    [ ' +
            '      ["Col1","Col2"], ' +           // group0.table1 -> PERCENT
            '      ["RowC","50"] ' +
            '    ] ' +
            '  ], ' +
            '  [ ' +
            '    [ ' +
            '      ["H1","H2"], ' +               // group1.table0 -> SUM (глобально №2)
            '      ["X","1"], ' +
            '      ["Y","2"] ' +
            '    ], ' +
            '    [ ' +
            '      ["H1","H2","H3"], ' +          // group1.table1 -> PERCENT (глобально №3)
            '      ["Z","9","8"] ' +
            '    ] ' +
            '  ] ' +
            ']';

            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(jsonBody);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    // --- Мок ошибки (например 500) ---
    private class MockHttp500 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error":"Internal"}');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    @IsTest
    static void test_success_inserts_and_clears_old_data() {
        // Предварительно создадим «старые» записи — они должны удалиться при успешном ответе.
        insert new API_Data__c(Column_1__c = 'OLD1', Row_Type__c = 'SUM');
        insert new API_Data2__c(Column_1__c = 'OLD2', Row_Type__c = 'SUM');

        Test.setMock(HttpCalloutMock.class, new MockHttp200());

        Test.startTest();
        ApiDataController.updateDataFromApi('2025-01-01', '2025-01-31', 'boostra');
        Test.stopTest();

        // Старых записей быть не должно
        System.assertEquals(0, [SELECT COUNT() FROM API_Data__c WHERE Column_1__c = 'OLD1']);
        System.assertEquals(0, [SELECT COUNT() FROM API_Data2__c WHERE Column_1__c = 'OLD2']);

        // В основной объект должно прилететь 6 строк (RowA, RowB, RowC, X, Y, Z)
        List<API_Data__c> dataAll = [
            SELECT Id, Row_Type__c, Column_1__c, Column_2__c, Column_3__c
            FROM API_Data__c
            ORDER BY CreatedDate ASC
        ];
        System.assertEquals(6, dataAll.size(), 'Ожидалось 6 записей в API_Data__c');

        // Проверим соответствие типов строк
        Map<String, String> expectedTypeByKey = new Map<String, String>{
            'RowA' => 'SUM',
            'RowB' => 'SUM',
            'RowC' => 'PERCENT',
            'X'    => 'SUM',
            'Y'    => 'SUM',
            'Z'    => 'PERCENT'
        };
        Set<String> seen = new Set<String>();
        for (API_Data__c rec : dataAll) {
            System.assertEquals(expectedTypeByKey.get(rec.Column_1__c), rec.Row_Type__c,
                'Неверный Row_Type__c у ' + rec.Column_1__c);
            seen.add(rec.Column_1__c);
        }
        System.assertEquals(expectedTypeByKey.keySet(), seen, 'Набор ключей не совпал');

        // Во второй объект — только глобальные таблицы №2 и №3: X, Y, Z
        List<API_Data2__c> data2All = [
            SELECT Id, Row_Type__c, Column_1__c, Column_2__c, Column_3__c
            FROM API_Data2__c
            ORDER BY CreatedDate ASC
        ];
        System.assertEquals(3, data2All.size(), 'Ожидалось 3 записи в API_Data2__c');

        Map<String, String> expected2 = new Map<String, String>{
            'X' => 'SUM',
            'Y' => 'SUM',
            'Z' => 'PERCENT'
        };
        for (API_Data2__c rec2 : data2All) {
            System.assertEquals(expected2.get(rec2.Column_1__c), rec2.Row_Type__c,
                'Неверный Row_Type__c в API_Data2__c у ' + rec2.Column_1__c);
        }
    }

    @IsTest
    static void test_non200_keeps_existing_and_does_not_insert() {
        // Создадим существующие записи — при не-200 твой контроллер делает return ДО удалений,
        // значит эти записи должны остаться.
        insert new API_Data__c(Column_1__c = 'TEMP_MAIN', Row_Type__c = 'SUM');
        insert new API_Data2__c(Column_1__c = 'TEMP_SECOND', Row_Type__c = 'SUM');

        Integer beforeMain = [SELECT COUNT() FROM API_Data__c];
        Integer beforeSecond = [SELECT COUNT() FROM API_Data2__c];

        Test.setMock(HttpCalloutMock.class, new MockHttp500());

        Test.startTest();
        ApiDataController.updateDataFromApi('2025-02-01', '2025-02-28', 'boostra');
        Test.stopTest();

        // Ничего не должно удалиться и ничего не должно добавиться
        Integer afterMain = [SELECT COUNT() FROM API_Data__c];
        Integer afterSecond = [SELECT COUNT() FROM API_Data2__c];

        System.assertEquals(beforeMain, afterMain,
            'При не-200 записи API_Data__c не должны меняться');
        System.assertEquals(beforeSecond, afterSecond,
            'При не-200 записи API_Data2__c не должны меняться');
    }
}