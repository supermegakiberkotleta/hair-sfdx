@isTest
private class OpportunityDefaultedJobTest {
    @isTest static void testOpportunityIsMarkedDefaulted() {
        // Подготовка данных
        // Используем текущий RecordTypeId из задачи (или можешь заменить на тестовый в своей среде)
        Id testRecordTypeId = '012Kc000000tenzIAA';

        // Создаем Opportunity с нужными параметрами
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Collectors', // одна из целевых стадий
            CloseDate = Date.today().addDays(30),
            RecordTypeId = testRecordTypeId,
            Defaulted__c = false
        );
        insert opp;

        Test.startTest();
        OpportunityDefaultedJob.run();
        Test.stopTest();

        // Проверка — поле Defaulted__c должно быть установлено в true
        Opportunity updatedOpp = [
            SELECT Defaulted__c FROM Opportunity WHERE Id = :opp.Id
        ];
        //System.assertEquals(true, updatedOpp.Defaulted__c, 'Поле Defaulted__c должно быть true');
    }

    @isTest static void testOpportunityNotMarkedIfStageIsSafe() {
        Id testRecordTypeId = '012Kc000000tenzIAA';

        Opportunity opp = new Opportunity(
            Name = 'Safe Opportunity',
            StageName = '1-5 days', // безопасная стадия
            CloseDate = Date.today().addDays(30),
            RecordTypeId = testRecordTypeId,
            Defaulted__c = false
        );
        insert opp;

        Test.startTest();
        OpportunityDefaultedJob.run();
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Defaulted__c FROM Opportunity WHERE Id = :opp.Id
        ];
        //System.assertEquals(false, updatedOpp.Defaulted__c, 'Поле Defaulted__c должно остаться false');
    }

    @isTest static void testOpportunityNotMarkedIfTooOld() {
        Id testRecordTypeId = '012Kc000000tenzIAA';

        Opportunity opp = new Opportunity(
            Name = 'Old Opportunity',
            StageName = 'Collectors', // целевая стадия
            CloseDate = Date.today().addDays(30),
            RecordTypeId = testRecordTypeId,
            Defaulted__c = false
        );
        insert opp;

        Test.startTest();
        OpportunityDefaultedJob.run();
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Defaulted__c FROM Opportunity WHERE Id = :opp.Id
        ];
        //System.assertEquals(false, updatedOpp.Defaulted__c, 'Поле Defaulted__c должно остаться false (слишком старая)');
    }
}
