# Обновление компонента сканирования лицензий

## Обзор изменений

Компонент `scanLicence` был обновлен для поддержки нового поля `Type__c` в объекте `Scan_Data__c`. Теперь все операции с этим объектом включают фильтрацию по типу `drive`.

## Изменения в ScanDataController.cls

### Метод getScanDataByLeadId
- ✅ Добавлено поле `Type__c` в SELECT запрос
- ✅ Добавлен фильтр `AND Type__c = 'drive'` для получения только записей типа "drive"

### Метод saveScanData
- ✅ Добавлен фильтр `AND Type__c = 'drive'` при поиске существующих записей
- ✅ При создании новой записи автоматически устанавливается `Type__c = 'drive'`

### Метод updateScanDataWithResult
- ✅ Добавлено поле `Type__c` в SELECT запрос
- ✅ Добавлен фильтр `AND Type__c = 'drive'` для обновления только записей типа "drive"

### Метод deleteScanData
- ✅ Добавлен фильтр `AND Type__c = 'drive'` для удаления только записей типа "drive"

## Изменения в ScanDataControllerTest.cls

### Обновленные тесты
- ✅ Все тесты теперь проверяют работу только с записями типа "drive"
- ✅ Добавлены проверки поля `Type__c` в тестах создания записей
- ✅ Обновлены SOQL запросы для включения фильтра по типу

### Новый тест
- ✅ Добавлен тест `testTypeFieldFiltering` для проверки корректной работы фильтрации по полю `Type__c`

## Совместимость

Все изменения обратно совместимы. Компонент продолжает работать как прежде, но теперь:
1. Создает записи только с типом "drive"
2. Работает только с записями типа "drive"
3. Не затрагивает записи с другими типами (например, "check")

## Структура объекта Scan_Data__c

Объект теперь включает следующие поля:
- `Id` - уникальный идентификатор
- `Lead__c` - связь с Lead
- `File_Id__c` - ID файла в ContentDocument
- `Name__c` - результат сканирования (имя)
- `Scan_Date__c` - дата сканирования
- `Type__c` - тип записи (picklist: "drive", "check")

## Использование

Компонент автоматически:
1. Создает записи с `Type__c = 'drive'`
2. Фильтрует все операции по типу "drive"
3. Не влияет на записи с другими типами

Никаких изменений в интерфейсе компонента не требуется - вся логика работает прозрачно для пользователя.

## Статус развертывания

✅ **Готово к развертыванию**

Все файлы обновлены и готовы к развертыванию:
- `ScanDataController.cls` - обновлен с поддержкой поля Type__c
- `ScanDataControllerTest.cls` - обновлен с тестами для поля Type__c
- `scanLicence.js` - не требует изменений (использует обновленные методы)
- Документация обновлена

## Команды для развертывания

```bash
# Развернуть обновленные классы
sfdx force:source:deploy --sourcepath force-app/main/default/classes/ScanDataController.cls,force-app/main/default/classes/ScanDataControllerTest.cls --targetusername YOUR_USERNAME --testlevel RunSpecifiedTests --runtests ScanDataControllerTest

# Или развернуть весь проект
sfdx force:source:deploy --sourcepath force-app/main/default/ --targetusername YOUR_USERNAME --testlevel RunLocalTests
``` 