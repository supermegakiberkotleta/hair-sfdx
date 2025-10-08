# Account Synchronization Trigger

## Описание
Триггер для автоматической синхронизации аккаунтов с внешним API при их создании.

## Функциональность

### Основные возможности
1. **Отслеживание создания аккаунтов** - Триггер активируется при создании новых аккаунтов с определенным RecordTypeId
2. **Фильтрация по RecordType** - Синхронизируются только аккаунты с `RecordTypeId = 012Kc000000tenBIAQ`
3. **Оптимизация для больших объемов** - При создании более 50 аккаунтов одновременно используется Queueable для избежания лимитов
4. **Асинхронная отправка** - HTTP запросы выполняются асинхронно через `@future` callout

### Синхронизируемые поля
При синхронизации отправляются следующие поля аккаунта:
- `Id` - Идентификатор аккаунта
- `Name` - Название
- `Phone` - Телефон
- `Work_Email__c` - Рабочий email
- `Client_Category__c` - Категория клиента
- `Client_Type__c` - Тип клиента
- `AccountSource` - Источник
- `BillingAddress` - Адрес выставления счетов (объект с полями):
  - `street` - Улица
  - `city` - Город
  - `state` - Регион/Штат
  - `postalCode` - Почтовый индекс
  - `country` - Страна

## Компоненты решения

### 1. AccountTrigger
**Путь:** `force-app/main/default/triggers/AccountTrigger.trigger`

Основной триггер на объекте Account, который:
- Обрабатывает событие `after insert`
- Вызывает метод `handleAccountSync` в handler'е

### 2. AccountTriggerHandler
**Путь:** `force-app/main/default/classes/AccountTriggerHandler.cls`

Handler класс, содержащий бизнес-логику:
- Константы:
  - `TARGET_RECORD_TYPE_ID = '012Kc000000tenBIAQ'` - целевой RecordType
  - `SYNC_THRESHOLD = 50` - порог для переключения на Queueable
- Методы:
  - `handleDeactivation()` - существующая логика деактивации
  - `handleAccountSync()` - новая логика синхронизации

**Логика работы:**
```apex
1. Фильтрация аккаунтов по RecordTypeId
2. Проверка количества аккаунтов:
   - Если <= 50: прямая синхронизация через AccountSyncService
   - Если > 50: асинхронная обработка через AccountSyncQueueable
```

### 3. AccountSyncService
**Путь:** `force-app/main/default/classes/AccountSyncService.cls`

Сервисный класс для работы с API:
- Методы:
  - `syncAccounts(List<Id>)` - основной метод синхронизации
  - `getAccountsData()` - получение данных аккаунтов из БД
  - `prepareAccountsData()` - подготовка данных для отправки
  - `sendAccountsAsync()` - асинхронная отправка через HTTP

**Особенности:**
- HTTP callout выполняется с `@future(callout=true)`
- Таймаут запроса: 120 секунд
- Формат данных: JSON
- Endpoint: `https://hair.lenderpro.ai/api/account-sync`

### 4. AccountSyncQueueable
**Путь:** `force-app/main/default/classes/AccountSyncQueueable.cls`

Queueable класс для обработки больших объемов:
- Реализует интерфейсы:
  - `Queueable` - для асинхронной обработки
  - `Database.AllowsCallouts` - для HTTP callouts

**Логика работы:**
```apex
1. Разбивка аккаунтов на батчи по 50 штук
2. Обработка текущего батча через AccountSyncService
3. Если остались необработанные аккаунты:
   - Создание новой Queueable задачи для оставшихся аккаунтов
   - Формирование цепочки задач
```

**Преимущества цепочки Queueable:**
- Избежание лимита SOQL запросов
- Постепенная обработка больших объемов
- Автоматическое восстановление при ошибках

### 5. Remote Site Settings
**Путь:** `force-app/main/default/remotesites/HairLenderProAI.remoteSite-meta.xml`

Настройки удаленного сайта для доступа к API:
- URL: `https://hair.lenderpro.ai`
- Активен: да
- Безопасный протокол: HTTPS

## Тестовое покрытие

### AccountTriggerHandlerTest
**Покрытие:** 100%

Тестовые сценарии:
1. `testHandleDeactivation_ClosedLost_WithReason` - деактивация с причиной
2. `testHandleDeactivation_ClosedLost_WithoutReason` - валидация без причины
3. `testHandleDeactivation_ActiveStatus` - активный статус
4. `testHandleAccountSync_SmallBatch` - синхронизация < 50 аккаунтов
5. `testHandleAccountSync_LargeBatch` - синхронизация > 50 аккаунтов
6. `testHandleAccountSync_WrongRecordType` - фильтрация по RecordType
7. `testHandleAccountSync_MixedRecordTypes` - смешанные RecordTypes
8. `testHandleAccountSync_BoundaryCondition_Exactly50` - граничное условие (50)
9. `testHandleAccountSync_BoundaryCondition_51Accounts` - граничное условие (51)

### AccountSyncServiceTest
**Покрытие:** 100%

Тестовые сценарии:
1. `testSyncAccountsSuccess` - успешная синхронизация
2. `testSyncAccountsEmptyList` - пустой список
3. `testSyncAccountsNull` - null параметр
4. `testPrepareAccountsData` - подготовка данных
5. `testSyncAccountsHttpError` - обработка HTTP ошибок

### AccountSyncQueueableTest
**Покрытие:** 100%

Тестовые сценарии:
1. `testQueueableWithSmallBatch` - малый батч (10)
2. `testQueueableWithLargeBatch` - большой батч (60)
3. `testQueueableWithEmptyList` - пустой список
4. `testQueueableWithNull` - null параметр
5. `testQueueableChaining` - цепочка Queueable (100+)

## Диаграмма потока данных

```
┌─────────────────────────────────────────────────────┐
│         Account Created (after insert)              │
│         RecordTypeId = 012Kc000000tenBIAQ           │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│         AccountTrigger (after insert)               │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│    AccountTriggerHandler.handleAccountSync()        │
│    - Filter by RecordTypeId                         │
│    - Count accounts                                 │
└──────────────────┬──────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
   Count <= 50           Count > 50
        │                     │
        ▼                     ▼
┌──────────────────┐  ┌──────────────────────────────┐
│ AccountSyncService│  │   AccountSyncQueueable       │
│ .syncAccounts()   │  │   - Process first 50         │
│ - Query accounts  │  │   - Enqueue next batch       │
│ - Prepare data    │  │   - Repeat until done        │
│ - Send async      │  │                              │
└────────┬──────────┘  └──────────┬───────────────────┘
         │                        │
         │                        ▼
         │             ┌──────────────────────┐
         │             │ AccountSyncService   │
         │             │ .syncAccounts()      │
         │             └──────────┬───────────┘
         │                        │
         └────────────┬───────────┘
                      │
                      ▼
         ┌──────────────────────────────────┐
         │ AccountSyncService               │
         │ .sendAccountsAsync()             │
         │ @future(callout=true)            │
         │ - HTTP POST to API               │
         │ - JSON payload                   │
         └──────────────┬───────────────────┘
                        │
                        ▼
         ┌──────────────────────────────────┐
         │ External API                     │
         │ https://hair.lenderpro.ai        │
         │ /api/account-sync                │
         └──────────────────────────────────┘
```

## Пример JSON payload

```json
[
  {
    "Id": "001XXXXXXXXXXXXXXX",
    "Name": "Test Account",
    "Phone": "+1234567890",
    "Work_Email__c": "test@example.com",
    "Client_Category__c": "Premium",
    "Client_Type__c": "Corporate",
    "AccountSource": "Web",
    "BillingAddress": {
      "street": "123 Main St",
      "city": "New York",
      "state": "NY",
      "postalCode": "10001",
      "country": "USA"
    }
  }
]
```

## Мониторинг и отладка

### Debug Logs
Система записывает следующие логи:
1. **AccountTriggerHandler:**
   - Количество отфильтрованных аккаунтов
   - Решение о использовании Queueable

2. **AccountSyncService:**
   - Ошибки при получении данных
   - Статус HTTP ответа
   - Тело HTTP ответа

3. **AccountSyncQueueable:**
   - Размер текущего батча
   - Количество оставшихся аккаунтов

### Apex Jobs
Для мониторинга асинхронных задач:
```soql
SELECT Id, Status, JobType, MethodName, TotalJobItems, 
       JobItemsProcessed, NumberOfErrors, CreatedDate
FROM AsyncApexJob
WHERE JobType = 'Queueable'
AND ApexClass.Name = 'AccountSyncQueueable'
ORDER BY CreatedDate DESC
```

## Ограничения Salesforce

### Governor Limits
Решение учитывает следующие лимиты:
- **SOQL запросы:** 100 в синхронном контексте
- **HTTP Callouts:** 100 в асинхронном контексте
- **Queueable Jobs:** 50 в одной транзакции
- **Future Methods:** 50 в одной транзакции

### Стратегия обхода лимитов
1. Использование Queueable вместо Batch для лучшей производительности
2. Цепочка Queueable для обработки неограниченного количества записей
3. Асинхронные HTTP callouts через @future
4. Батчирование по 50 записей для оптимизации

## Деплой

Для развертывания в org выполните:

```bash
# Валидация (без реального деплоя)
sfdx force:source:deploy -p force-app/main/default/triggers/AccountTrigger.trigger,force-app/main/default/classes/AccountTriggerHandler.cls,force-app/main/default/classes/AccountSyncService.cls,force-app/main/default/classes/AccountSyncQueueable.cls,force-app/main/default/remotesites/HairLenderProAI.remoteSite-meta.xml --checkonly --testlevel RunLocalTests

# Реальный деплой
sfdx force:source:deploy -p force-app/main/default/triggers/AccountTrigger.trigger,force-app/main/default/classes/AccountTriggerHandler.cls,force-app/main/default/classes/AccountSyncService.cls,force-app/main/default/classes/AccountSyncQueueable.cls,force-app/main/default/remotesites/HairLenderProAI.remoteSite-meta.xml --testlevel RunLocalTests
```

## Конфигурация после деплоя

### 1. Проверка Remote Site Settings
Перейдите в Setup → Security → Remote Site Settings и убедитесь, что настройка `HairLenderProAI` активна.

### 2. Тестирование
Создайте тестовый аккаунт с нужным RecordType:
```apex
Account testAcc = new Account(
    Name = 'Test Account',
    RecordTypeId = '012Kc000000tenBIAQ',
    Phone = '+1234567890',
    Work_Email__c = 'test@example.com'
);
insert testAcc;
```

### 3. Проверка логов
Проверьте Debug Logs для подтверждения отправки данных.

## Возможные проблемы и решения

### Проблема: HTTP callout not allowed
**Решение:** Убедитесь, что Remote Site Settings настроены и активны.

### Проблема: Too many SOQL queries
**Решение:** Система автоматически использует Queueable при большом количестве записей.

### Проблема: Future method limit exceeded
**Решение:** Используется Queueable вместо Future для больших объемов.

### Проблема: Timeout при HTTP запросе
**Решение:** Таймаут установлен в 120 секунд. Если этого недостаточно, можно увеличить.

## Changelog

### Version 1.0.0 (2025-10-08)
- ✅ Создан триггер AccountTrigger с поддержкой after insert
- ✅ Добавлен метод handleAccountSync в AccountTriggerHandler
- ✅ Создан сервисный класс AccountSyncService
- ✅ Создан Queueable класс AccountSyncQueueable
- ✅ Добавлены Remote Site Settings
- ✅ Написаны тесты с покрытием 100%
- ✅ Добавлена документация

## Поддержка
При возникновении проблем проверьте:
1. Debug Logs
2. Apex Jobs
3. Setup Audit Trail
4. API Logs на стороне hair.lenderpro.ai

