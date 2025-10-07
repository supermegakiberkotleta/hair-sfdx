trigger TrackLeadStatus on Lead (after insert, after update) {
    // Этот триггер теперь интегрирован в UnifiedLeadProcessor
    // Логика перенесена в LeadWebhookUpdate для избежания дублирования Queueable jobs
}