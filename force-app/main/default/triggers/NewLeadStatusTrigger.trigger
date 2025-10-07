trigger NewLeadStatusTrigger on Lead (after update) {
    // Этот триггер отключен - функциональность перенесена в UnifiedLeadProcessor
    // для избежания конфликтов с множественными Queueable jobs
}