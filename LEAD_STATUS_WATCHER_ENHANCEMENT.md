# Улучшение компонента leadStatusWatcher

## Описание проблемы

Компонент `leadStatusWatcher` иногда не может отследить предыдущий статус лида в реальном времени и возвращает лид в статус "New" при отмене конвертации. Это происходит в случаях:

- Быстрых изменений статуса
- Проблем с сетью или производительностью
- Отсутствия предыдущего статуса в памяти компонента

## Решение

Добавлена возможность получения предыдущего статуса из Lead Status History как fallback механизм.

## Новые компоненты

### 1. LeadStatusHistoryController.cls
**Файл**: `force-app/main/default/classes/LeadStatusHistoryController.cls`

**Функциональность**:
- `getPreviousStatus(Id leadId)` - получает предыдущий статус из Lead Status History
- `getStatusHistory(Id leadId)` - получает полную историю статусов лида
- Поддержка как Lead Status History, так и стандартной истории Salesforce

**Методы**:
```apex
@AuraEnabled(cacheable=true)
public static String getPreviousStatus(Id leadId)

@AuraEnabled(cacheable=true)
public static List<String> getStatusHistory(Id leadId)
```

### 2. LeadStatusHistoryControllerTest.cls
**Файл**: `force-app/main/default/classes/LeadStatusHistoryControllerTest.cls`

**Покрытие тестами**:
- Получение предыдущего статуса из истории
- Обработка лидов без истории
- Получение полной истории статусов
- Обработка неверных ID

## Обновленные компоненты

### leadStatusWatcher.js
**Изменения**:
- Добавлен импорт `getPreviousStatus` из Apex контроллера
- Добавлено поле `isLoadingPreviousStatus` для отслеживания состояния загрузки
- Добавлен метод `getPreviousStatusFromHistory()` для получения предыдущего статуса из истории
- Улучшена логика определения предыдущего статуса

**Новая логика**:
1. При изменении статуса на "Call after" проверяется наличие предыдущего статуса
2. Если предыдущий статус отсутствует или равен "New", вызывается `getPreviousStatusFromHistory()`
3. Если из истории получен валидный статус, он используется для возврата
4. В случае ошибки или отсутствия истории используется "New" как fallback

## Логика работы

### Сценарий 1: Нормальная работа
1. Пользователь изменяет статус лида на "Call after"
2. Компонент отслеживает изменение в реальном времени
3. Предыдущий статус сохраняется в `previousStatus`
4. Открывается модальное окно конвертации

### Сценарий 2: Fallback к истории
1. Пользователь изменяет статус лида на "Call after"
2. Компонент не может определить предыдущий статус
3. Вызывается `getPreviousStatusFromHistory()`
4. Из Lead Status History получается предыдущий статус
5. Открывается модальное окно конвертации с правильным предыдущим статусом

### Сценарий 3: Обработка ошибок
1. Пользователь изменяет статус лида на "Call after"
2. Компонент не может определить предыдущий статус
3. Вызывается `getPreviousStatusFromHistory()`
4. Происходит ошибка при получении истории
5. Используется "New" как fallback статус
6. Открывается модальное окно конвертации

## Установка

### 1. Развертывание новых компонентов
```bash
sfdx force:source:deploy -p force-app/main/default/classes/LeadStatusHistoryController.cls
sfdx force:source:deploy -p force-app/main/default/classes/LeadStatusHistoryControllerTest.cls
```

### 2. Обновление существующего компонента
```bash
sfdx force:source:deploy -p force-app/main/default/lwc/leadStatusWatcher/
```

### 3. Запуск тестов
```bash
sfdx force:apex:test:run -n LeadStatusHistoryControllerTest
```

## Преимущества

1. **Надежность**: Гарантированное получение предыдущего статуса даже при проблемах с отслеживанием
2. **Точность**: Использование реальной истории статусов вместо предположений
3. **Fallback механизм**: Множественные уровни резервирования для обеспечения работы
4. **Производительность**: Кэшируемые запросы к Apex контроллеру
5. **Обработка ошибок**: Graceful degradation при проблемах с получением истории

## Мониторинг

### Логи для отслеживания
- `console.warn('Could not determine previous status from history, using "New" as fallback')`
- `console.error('Error getting previous status from history:', error)`

### Метрики для мониторинга
- Количество обращений к Lead Status History
- Количество случаев использования fallback статуса "New"
- Время выполнения запросов к истории

## Требования

- Salesforce API версия 58.0+
- Объект Lead_Status_History__c должен быть настроен
- Триггер TrackLeadStatus должен быть активен для записи истории
- Права доступа к объектам Lead и Lead_Status_History__c

## Поддержка

При возникновении проблем:
1. Проверьте логи в Developer Console
2. Убедитесь, что Lead Status History настроен корректно
3. Проверьте права доступа пользователя
4. Запустите тесты для проверки функциональности 