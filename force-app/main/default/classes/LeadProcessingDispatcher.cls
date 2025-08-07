/**
 * Централизованный диспетчер для управления процессами обработки лидов
 * Предотвращает конфликты между различными Queueable и Batch jobs
 */
public class LeadProcessingDispatcher {
    
    // Статические флаги для отслеживания запущенных процессов
    private static Boolean isDeniedStatusProcessing = false;
    
    // Очередь для отложенной обработки
    private static List<ProcessingRequest> pendingRequests = new List<ProcessingRequest>();
    
    /**
     * Внутренний класс для хранения запросов на обработку
     */
    public class ProcessingRequest {
        public String processType;
        public Object data;
        public DateTime requestTime;
        
        public ProcessingRequest(String processType, Object data) {
            this.processType = processType;
            this.data = data;
            this.requestTime = DateTime.now();
        }
    }
    
    /**
     * Запуск обработки статуса DENIED
     */
    public static void processDeniedStatus(List<Lead> leads) {
        if (!isDeniedStatusProcessing && canStartProcess('DENIED_STATUS')) {
            isDeniedStatusProcessing = true;
            LeadDeniedStatusBatch.startBatch(leads);
            System.debug('LeadProcessingDispatcher: Started DENIED status processing');
        } else {
            pendingRequests.add(new ProcessingRequest('DENIED_STATUS', leads));
            System.debug('LeadProcessingDispatcher: DENIED status processing queued');
        }
    }
    
    /**
     * Проверяет, можно ли запустить процесс
     */
    private static Boolean canStartProcess(String processType) {
        if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
            return false;
        }
        return true;
    }
    
    /**
     * Сброс флага завершения процесса
     */
    public static void markProcessComplete(String processType) {
        if (processType == 'DENIED_STATUS') {
            isDeniedStatusProcessing = false;
        }
        
        processPendingRequests();
    }
    
    /**
     * Обработка отложенных запросов
     */
    private static void processPendingRequests() {
        if (pendingRequests.isEmpty()) {
            return;
        }
        
        List<ProcessingRequest> requestsToProcess = new List<ProcessingRequest>(pendingRequests);
        pendingRequests.clear();
        
        for (ProcessingRequest request : requestsToProcess) {
            if (DateTime.now().addMinutes(-5) > request.requestTime) {
                System.debug('LeadProcessingDispatcher: Skipping stale request: ' + request.processType);
                continue;
            }
            
            if (request.processType == 'DENIED_STATUS' && !isDeniedStatusProcessing && canStartProcess('DENIED_STATUS')) {
                processDeniedStatus((List<Lead>) request.data);
            } else {
                pendingRequests.add(request);
            }
        }
    }
    
    /**
     * Получение статуса всех процессов
     */
    public static Map<String, Boolean> getProcessingStatus() {
        return new Map<String, Boolean>{
            'DENIED_STATUS' => isDeniedStatusProcessing
        };
    }
    
    /**
     * Получение количества отложенных запросов
     */
    public static Integer getPendingRequestsCount() {
        return pendingRequests.size();
    }
    
    /**
     * Получение информации об отложенных запросах
     */
    public static List<String> getPendingRequestsInfo() {
        List<String> info = new List<String>();
        for (ProcessingRequest request : pendingRequests) {
            info.add(request.processType);
        }
        return info;
    }
    
    /**
     * Очистка всех флагов (для тестирования)
     */
    public static void resetAllFlags() {
        isDeniedStatusProcessing = false;
        pendingRequests.clear();
    }
}