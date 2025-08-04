global class OpportunityDefaultedScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        OpportunityDefaultedJob.run();
    }
}