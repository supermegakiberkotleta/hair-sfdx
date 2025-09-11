@IsTest
public class TaskControllerTest {
    @IsTest
    static void testAllMethods() {
        // Создаём фиктивную Opportunity
        Opportunity opp = new Opportunity(Name='Test Opp', StageName='Prospecting', CloseDate=Date.today(), Missed_Payment_Count__c=2);
        insert opp;

        // Создаём Task
        Task t = new Task(
            Subject = 'Test Task',
            WhatId = opp.Id,
            OwnerId = UserInfo.getUserId(),
            Status = 'Not Started',
            ActivityDate = Date.today()
        );
        insert t;

        // Вызов getTasksByOpportunity
        TaskController.TaskWrapper wrapper = TaskController.getTasksByOpportunity(opp.Id);
        System.assert(wrapper.tasks.size() == 1);

        // Вызов updateTask
        TaskController.updateTask(t.Id, 'Completed', Date.today());

        // Вызов getActivityDetailsForTask
        Map<String, List<sObject>> activities = TaskController.getActivityDetailsForTask(t.Id, t.ActivityDate);
        System.assert(activities != null);
    }
}