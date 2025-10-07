# System Notifications Event Trigger

## Описание
Система уведомлений на основе платформы событий Salesforce для автоматической отправки уведомлений через `NotificationController`.

## Компоненты

### 1. Платформа событий System_Notifications__e
- **Title__c** (Text, 255 символов, обязательное) - заголовок уведомления
- **Message__c** (LongTextArea, 32768 символов) - текст уведомления  
- **Type__c** (Text, 50 символов) - тип уведомления (info, success, warning, error)
- **User__c** (Text, 18 символов, обязательное) - ID пользователя-получателя
- **Target__c** (Text, 18 символов, обязательное) - ID целевого объекта

### 2. Триггер SystemNotificationsEventTrigger
- Срабатывает при создании события (after insert)
- Вызывает обработчик `SystemNotificationsEventHandler.handleAfterInsert()`

### 3. Обработчик SystemNotificationsEventHandler
- Обрабатывает события после вставки
- Вызывает `NotificationController.sendNotification()` для каждого события
- Включает обработку ошибок с логированием

### 4. Тестовый класс SystemNotificationsEventTriggerTest
- Покрывает все сценарии использования
- Тестирует одиночные и множественные события
- Тестирует обработку некорректных данных
- Интегрированное тестирование с NotificationController

## Использование

### Публикация события из Apex кода:
```apex
System_Notifications__e notificationEvent = new System_Notifications__e(
    Title__c = 'Важное уведомление',
    Message__c = 'Это важное сообщение для пользователя',
    Type__c = 'info',
    User__c = '005000000000000AAA', // ID пользователя
    Target__c = '001000000000000AAA' // ID целевого объекта
);

EventBus.publish(notificationEvent);
```

### Публикация события из Flow/Process Builder:
1. Используйте элемент "Platform Event" в Flow
2. Заполните поля: Title, Message, Type, User, Target
3. Сохраните и активируйте Flow

## Логика работы
1. При создании события `System_Notifications__e` срабатывает триггер
2. Триггер вызывает обработчик `SystemNotificationsEventHandler`
3. Обработчик извлекает данные из события и вызывает `NotificationController.sendNotification()`
4. `NotificationController` отправляет уведомление через Salesforce notification system
5. В случае ошибки происходит fallback на email уведомления

## Обработка ошибок
- Все ошибки логируются в System.debug
- Ошибки в обработке одного события не блокируют обработку других
- При недоступности custom notifications происходит fallback на email

## Требования
- NotificationController должен быть развернут и активен
- Custom Notification Type с DeveloperName = 'System_Notifications' должен существовать
- Пользователи должны иметь корректные email адреса для fallback уведомлений
