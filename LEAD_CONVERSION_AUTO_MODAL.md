# Автоматический попап конвертации лидов

## Описание функциональности

Система автоматически открывает попап конвертации лида при изменении статуса на "Call after". Если конвертация не была настроена корректно, лид возвращается к предыдущему статусу.

## Компоненты

### 1. leadConversionModal (обновлен)
- **Файлы**: `force-app/main/default/lwc/leadConversionModal/`
- **Функциональность**: 
  - Поддержка автоматического открытия при изменении статуса
  - Возврат к предыдущему статусу при отмене
  - Проверка обязательных полей при открытии

### 2. leadStatusWatcher (новый)
- **Файлы**: `force-app/main/default/lwc/leadStatusWatcher/`
- **Функциональность**:
  - Отслеживание изменений статуса лида
  - Автоматическое открытие попапа при статусе "Call after"
  - Передача предыдущего статуса для возврата

### 3. LeadConversionController (обновлен)
- **Файлы**: `force-app/main/default/classes/LeadConversionController.cls`
- **Функциональность**:
  - Конвертация лида с созданием Account, Contact и Opportunity
  - Валидация обязательных полей
  - Возврат детального результата конвертации

## Установка и настройка

### 1. Развертывание компонентов
```bash
sfdx force:source:deploy -p force-app/main/default/lwc/leadConversionModal/
sfdx force:source:deploy -p force-app/main/default/lwc/leadStatusWatcher/
sfdx force:source:deploy -p force-app/main/default/classes/LeadConversionController.cls
sfdx force:source:deploy -p force-app/main/default/classes/LeadConversionControllerTest.cls
```

### 2. Добавление компонента на страницу лида
Добавьте компонент `c-lead-status-watcher` на страницу записи лида:

```xml
<aura:component>
    <c:leadStatusWatcher record-id="{!v.recordId}"></c:leadStatusWatcher>
</aura:component>
```

### 3. Обновление триггера
Триггер `LoanLeadsConvertedTrigger` уже обновлен для поддержки новой логики.

## Использование

### Автоматическое открытие попапа
1. Измените статус лида на "Call after"
2. Попап конвертации автоматически откроется
3. Заполните все обязательные поля
4. Нажмите "Validate & Continue" для перехода к конвертации
5. Нажмите "Start Conversion" для завершения конвертации

### Возврат к предыдущему статусу
Если пользователь отменяет конвертацию:
1. Нажмите "Cancel" или "Close"
2. Лид автоматически вернется к предыдущему статусу
3. Появится уведомление о возврате

### Ручное открытие попапа
Кнопка "Validate & Convert" по-прежнему доступна для ручного открытия попапа.

## Обязательные поля для конвертации

- Final Daily Payment (`Final_Daily_payment__c`)
- Final Purchased Amount of Future (`Final_purchased_Amount_of_Future_New__c`)
- Payment Frequency (`Payment_Frequency__c`)
- Loan Start Date (`Loan_Start_Date__c`)
- Final Term (`Final_Term__c`)
- Client Email (`Client_email__c`)
- Lender Type (`Lender_type__c`)

## Логика работы

1. **Отслеживание статуса**: `leadStatusWatcher` отслеживает изменения статуса лида
2. **Автоматическое открытие**: При статусе "Call after" автоматически открывается попап
3. **Валидация**: Проверяются все обязательные поля
4. **Конвертация**: При успешной валидации создаются Account, Contact и Opportunity
5. **Возврат**: При отмене лид возвращается к предыдущему статусу

## Тестирование

Запустите тесты:
```bash
sfdx force:apex:test:run -n LeadConversionControllerTest
```

## Требования

- Salesforce API версия 58.0+
- RecordType "Loan_Leads" для лидов
- RecordType "012Kc000000tenzIAA" для Opportunities (в продакшене)

## Поддержка

При возникновении проблем:
1. Проверьте логи в Developer Console
2. Убедитесь, что все RecordType настроены корректно
3. Проверьте права доступа пользователя к объектам Lead, Account, Contact, Opportunity 