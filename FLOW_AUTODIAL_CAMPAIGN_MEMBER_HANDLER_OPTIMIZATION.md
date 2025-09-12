# FlowAutodialCampaignMemberHandler Optimization

## Проблема

При добавлении большого количества записей (более 50) в объект `Autodial_CampaignMembers__c` возникала ошибка:

```
Error: Failed to create campaign members - Insert failed. First exception on row 0; first error: CANNOT_EXECUTE_FLOW_TRIGGER, We can't save this record because the "Autodial Campaign Members Prepaire" process failed. Give your Salesforce admin these details. This error occurred when the flow tried to update records: LIMIT_EXCEEDED: System.LimitException: Too many queueable jobs added to the queue: 51.
```

## Причина

Ошибка возникала из-за превышения лимита Salesforce на количество queueable jobs (максимум 50). При вставке большого количества записей:

1. Триггер `AutodialCampaignMembersTrigger` вызывал `AutodialCampaignMembersCallout.enqueueCreate()`
2. Создавался один queueable job для всех записей
3. Внутри job'а для каждой записи выполнялся HTTP callout
4. Процесс "Autodial Campaign Members Prepaire" также создавал queueable jobs
5. Общее количество queueable jobs превышало лимит в 50

## Решение

### 1. Модификация FlowAutodialCampaignMemberHandler

- **Пакетная обработка**: Добавлена функция `processRecordsInBatches()` для обработки записей пакетами по 200 (лимит DML)
- **Единый метод с параметром**: Объединены методы в один `addCampaignMembers()` с параметром `useBatchProcessing`
- **Улучшенная обработка ошибок**: Добавлена обработка ошибок на уровне пакетов с возможностью частичного успеха

### 2. Обновление AutodialCampaignMembersCallout

- **Условная логика**: Для объемов >50 записей используется batch processing вместо queueable jobs
- **Batch processing**: Интеграция с `AutodialCampaignMembersBatch` для больших объемов данных

### 3. Новый класс AutodialCampaignMembersBatch

- **Batchable интерфейс**: Реализует `Database.Batchable<Id>` для обработки больших объемов
- **Chunked processing**: Обрабатывает записи чанками по 10 для избежания лимитов callout'ов
- **Поддержка операций**: Поддерживает create, update, delete операции
- **Улучшенная обработка ошибок**: Логирование ошибок HTTP callout'ов

## Использование

### Единый метод с параметром batch processing
```apex
FlowAutodialCampaignMemberHandler.CampaignMemberRequest request = 
    new FlowAutodialCampaignMemberHandler.CampaignMemberRequest();
request.recordIds = recordIds;
request.objectType = 'Lead';
request.autodialId = campaignId;
request.useBatchProcessing = false; // для обычных объемов (до 50 записей)
// request.useBatchProcessing = true; // для больших объемов (50+ записей)

List<String> results = FlowAutodialCampaignMemberHandler.addCampaignMembers(
    new List<FlowAutodialCampaignMemberHandler.CampaignMemberRequest>{request}
);
```

### Автоматическое переключение в AutodialCampaignMembersCallout
`AutodialCampaignMembersCallout.enqueueCreate()` автоматически выбирает:
- Queueable jobs для объемов ≤50 записей
- Batch processing для объемов >50 записей

## Преимущества

1. **Устранение лимитов**: Решение проблемы с превышением лимита queueable jobs
2. **Масштабируемость**: Поддержка обработки тысяч записей
3. **Надежность**: Улучшенная обработка ошибок и частичный успех
4. **Производительность**: Оптимизированная обработка больших объемов данных
5. **Обратная совместимость**: Существующий код продолжает работать

## Тестирование

Созданы comprehensive тесты:
- `FlowAutodialCampaignMemberHandlerTest`: Тестирование всех сценариев Flow handler'а
- `AutodialCampaignMembersBatchTest`: Тестирование batch processing

## Рекомендации

1. **Для малых объемов** (до 50 записей): Используйте `useBatchProcessing = false`
2. **Для средних объемов** (50-1000 записей): Используйте `useBatchProcessing = true`
3. **Для очень больших объемов** (>1000 записей): Batch processing запускается автоматически
4. **Мониторинг**: Следите за логами batch jobs в Setup > Apex Jobs

## Файлы изменены

- `FlowAutodialCampaignMemberHandler.cls` - Основная логика с пакетной обработкой
- `AutodialCampaignMembersCallout.cls` - Условная логика для выбора queueable/batch
- `AutodialCampaignMembersBatch.cls` - Новый batch класс для больших объемов
- `FlowAutodialCampaignMemberHandlerTest.cls` - Тесты для Flow handler'а
- `AutodialCampaignMembersBatchTest.cls` - Тесты для batch класса
