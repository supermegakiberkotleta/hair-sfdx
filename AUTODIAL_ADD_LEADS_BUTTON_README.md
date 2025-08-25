# Autodial Add Leads Button Component

## Описание
Компонент `autodialAddLeadsButton` представляет собой кнопку, которая при нажатии открывает модальное окно с компонентом `autodialAddLeads` для добавления лидов в автодиал кампанию.

## Структура компонента
```
autodialAddLeadsButton/
├── autodialAddLeadsButton.js          # Основная логика компонента
├── autodialAddLeadsButton.html        # HTML разметка
├── autodialAddLeadsButton.css         # Стили компонента
└── autodialAddLeadsButton.js-meta.xml # Мета-данные компонента

autodialAddLeadsModal/
├── autodialAddLeadsModal.js           # Логика модального окна
├── autodialAddLeadsModal.html         # HTML модального окна
├── autodialAddLeadsModal.css          # Стили модального окна
└── autodialAddLeadsModal.js-meta.xml  # Мета-данные модального окна
```

## Возможности
- Открывает модальное окно с компонентом для добавления лидов
- Передает `recordId` кампании в модальное окно
- Настраиваемая метка кнопки
- Использует Salesforce Lightning Design System
- Автоматически закрывает модальное окно после успешного добавления лидов
- Работает как action на странице записи без промежуточных кнопок

## Использование

### 1. Добавление как Action на страницу записи
1. Откройте Setup → Object Manager → Autodial Campaign
2. Перейдите в Lightning Record Pages
3. Отредактируйте нужную страницу
4. В разделе Actions добавьте новый Action
5. Выберите компонент `autodialAddLeadsButton`

### 2. Программное использование
```html
<c:autodialAddLeadsButton 
    record-id={campaignId} 
    label="Add Leads to Campaign">
</c:autodialAddLeadsButton>
```

## Параметры
- `recordId` (String, обязательный) - ID записи Autodial Campaign
- `label` (String, опциональный) - Метка кнопки (по умолчанию: "Add Leads")

## Зависимости
- Компонент `autodialAddLeads` должен быть доступен в системе
- Компонент `autodialAddLeadsModal` должен быть доступен в системе
- Требуется API версия 59.0 или выше
- Необходимы права на выполнение Apex методов `AutodialCampaignMemberController.searchLeads` и `AutodialCampaignMemberController.addMembers`

## Особенности
- Модальное окно автоматически закрывается после успешного добавления лидов
- Компонент поддерживает поиск и выбор лидов
- Использует debounce для поиска (350ms)
- Показывает toast уведомления об успехе/ошибке
- Использует NavigationMixin для корректной работы как action
- Модальное окно имеет собственный заголовок и кнопку закрытия

## Тестирование
Рекомендуется протестировать компонент в следующих сценариях:
1. Открытие модального окна
2. Поиск лидов
3. Выбор и добавление лидов
4. Закрытие модального окна
5. Обработка ошибок
