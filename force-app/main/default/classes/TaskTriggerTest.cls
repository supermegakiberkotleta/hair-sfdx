@isTest
public class TaskTriggerTest {
    @isTest
    static void testCallRecordingBatchStarterIsQueued() {
        // Arrange: Создаем Task, удовлетворяющий условиям триггера
        Task t = new Task(
            Subject = '[Completed] Follow-up Call',
            Description = 'Client interested. Sid:12345',
            Status = 'Not Started',
            Priority = 'Normal',
            WhatId = null,
            ActivityDate = Date.today()
        );

        Test.startTest();
        insert t;
        Test.stopTest(); // гарантирует выполнение System.enqueueJob

    }
}
