# ObjectUpdateService Flow Optimization

## Проблема

При использовании `ObjectUpdateService` в scheduled Flow возникала ошибка:
```
System.LimitException: Too many queueable jobs added to the queue: 2
```

## Анализ проблемы

Из лога выполнения видно, что проблема возникает не в самом `ObjectUpdateService`, а в каскадных триггерах:

1. **ObjectUpdateBatch** успешно обновляет 94 записи Lead
2. Срабатывают триггеры Lead, включая `LeadWebhookUpdate` который добавляет queueable job
3. Затем срабатывает `NewLeadStatusTrigger` который пытается добавить еще один queueable job
4. Лимит исчерпан: `Number of queueable jobs added to the queue: 1 out of 1`

## Решение

### 1. Отключение батч-обработки для Flow контекста

Добавлена константа `DISABLE_BATCH_FOR_FLOW = true`, которая полностью отключает батч-обработку для Flow контекста:

```apex
// Flag to completely disable batch processing in Flow context
// This prevents cascade trigger issues that lead to queueable job limit errors
private static final Boolean DISABLE_BATCH_FOR_FLOW = true;
```

### 2. Обновленная логика принятия решений

```apex
Boolean shouldUseBatch = request.recordIds.size() > BATCH_THRESHOLD && 
                       !isInAsyncContext && 
                       !DISABLE_BATCH_FOR_FLOW;
```

### 3. Обработка больших объемов данных

Для больших объемов данных (>200 записей) используется обработка по частям:

```apex
// For large datasets, process in chunks to avoid governor limits
// This is especially important in Flow context to prevent cascade trigger issues
if (recordIds.size() > MAX_SYNC_RECORDS) {
    return processLargeDatasetInChunks(recordIds, objectType, fieldsMap, objectSchema);
}
```

## Логика работы

| Количество записей | Контекст выполнения | Метод обработки |
|-------------------|-------------------|-----------------|
| ≤ 50 | Любой | Синхронная обработка |
| 51-200 | Синхронный | Синхронная обработка (батч отключен) |
| 51-200 | Асинхронный | Синхронная обработка |
| > 200 | Любой | Обработка по частям (200 записей за раз) |

## Преимущества решения

1. **Решает проблему с scheduled Flow** - больше нет ошибки `Too many queueable jobs`
2. **Предотвращает каскадные триггеры** - синхронная обработка не запускает дополнительные queueable jobs
3. **Обратная совместимость** - существующие Flow продолжают работать
4. **Масштабируемость** - может обрабатывать тысячи записей по частям
5. **Надежность** - обработка ошибок на уровне отдельных частей

## Рекомендации

1. **Для Flow контекста** - всегда используется синхронная обработка или обработка по частям
2. **Для больших объемов** - данные обрабатываются по 200 записей за раз
3. **Мониторинг** - следите за лимитами DML операций при обработке больших объемов
4. **Триггеры** - убедитесь, что триггеры Lead не добавляют queueable jobs при массовых обновлениях

## Тестирование

Добавлены тесты для:
- Обработки в асинхронном контексте (имитация scheduled Flow)
- Обработки больших наборов данных по частям
- Проверки определения контекста выполнения

## Важные замечания

- Батч-обработка полностью отключена для Flow контекста
- Для больших объемов используется обработка по частям
- Каскадные триггеры могут вызывать проблемы с лимитами queueable jobs
- Рекомендуется оптимизировать триггеры Lead для массовых операций

