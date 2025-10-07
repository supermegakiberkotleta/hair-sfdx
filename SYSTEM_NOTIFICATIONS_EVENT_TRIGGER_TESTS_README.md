# Тесты для System Notifications Event Trigger

## Описание
Полное покрытие тестами для системы уведомлений на основе платформы событий `System_Notifications__e`.

## Тестовые классы

### 1. SystemNotificationsEventTriggerTest
Основной тестовый класс для проверки интеграции всей системы:

#### Методы тестирования:
- **testSystemNotificationsEventTrigger()** - базовый тест публикации события
- **testSystemNotificationsEventHandlerWithMultipleEvents()** - тест множественных событий
- **testSystemNotificationsEventHandlerWithInvalidData()** - тест обработки некорректных данных
- **testNotificationControllerIntegration()** - интеграционный тест с NotificationController
- **testTriggerAfterInsertExecution()** - специфичный тест выполнения триггера
- **testEventHandlerWithEmptyFields()** - тест обработки пустых полей
- **testEventHandlerExceptionHandling()** - тест обработки исключений
- **testBulkEventProcessing()** - тест массовой обработки событий

### 2. SystemNotificationsHandlerTest
Специализированный тестовый класс для тестирования обработчика триггера:

#### Методы тестирования:
- **testTriggerHandlerAfterInsert()** - тест основного сценария after insert
- **testTriggerHandlerWithNullValues()** - тест обработки null значений
- **testTriggerHandlerExceptionScenario()** - тест сценариев исключений
- **testTriggerHandlerBulkProcessing()** - тест массовой обработки (10 событий)
- **testTriggerHandlerDirectCall()** - прямой вызов обработчика

## Исправленные проблемы

### DUPLICATE_USERNAME Error
**Проблема:** Использование фиксированного username в тестах приводило к ошибке `DUPLICATE_USERNAME`.

**Решение:** 
- Генерация уникального username с использованием `System.currentTimeMillis()`
- Использование email для поиска пользователя вместо username
- Уникальные alias для каждого тестового пользователя

### Покрытие тестами
**Добавлено:**
- Тестирование всех сценариев триггера (after insert)
- Тестирование обработки ошибок в обработчике
- Тестирование bulk операций
- Тестирование null значений и некорректных данных
- Прямое тестирование методов обработчика

## Сценарии тестирования

### ✅ Положительные сценарии:
- Успешная публикация события
- Обработка множественных событий
- Bulk обработка (до 10 событий)
- Интеграция с NotificationController

### ⚠️ Граничные случаи:
- Пустые поля (null значения)
- Некорректные ID пользователей и объектов
- Обработка исключений

### 🔧 Технические тесты:
- Прямой вызов обработчика
- Переопределение notificationTypeIdOverride
- Логирование результатов

## Запуск тестов

```bash
# Запуск всех тестов системы уведомлений
sfdx force:apex:test:run -n SystemNotificationsEventTriggerTest,SystemNotificationsHandlerTest

# Запуск конкретного тестового класса
sfdx force:apex:test:run -n SystemNotificationsEventTriggerTest

# Запуск с подробным выводом
sfdx force:apex:test:run -n SystemNotificationsEventTriggerTest -r human
```

## Ожидаемые результаты
- Все тесты должны проходить успешно
- Покрытие кода должно быть 100% для триггера и обработчика
- Обработка ошибок должна работать корректно
- Bulk операции должны обрабатываться без проблем
