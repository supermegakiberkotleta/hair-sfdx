public with sharing class LeadMassDeleteController {
    private ApexPages.StandardSetController ssc;

    public LeadMassDeleteController(ApexPages.StandardSetController ssc){
        this.ssc = ssc;
        // Подстрахуемся на максимум разрешённых за раз
        this.ssc.setPageSize(2000);
    }

    public PageReference doDelete(){
        // Получаем выбранные ID из related list / list view
        List<SObject> selected = ssc.getSelected();
        List<Id> ids = new List<Id>();
        if (selected != null) {
            for (SObject sob : selected) {
                if (sob != null) ids.add((Id)sob.get('Id'));
            }
        }

        if(ids == null || ids.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No records selected.'));
            return null;
        }

        Integer deletedCount = 0;
        try {
            // Лучше перечитать записи SOQL'ом: так исключим случайные read-only экземпляры
            List<Lead> toDelete =
                [SELECT Id FROM Lead WHERE Id IN :ids];

            // DML (за один вызов можно до 10k; пользователи обычно отмечают не больше пары тысяч)
            delete toDelete;
            deletedCount = toDelete.size();

            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.CONFIRM,
                deletedCount + ' lead(s) removed.'
            ));
        } catch (DmlException e){
            ApexPages.addMessages(e);
            return null;
        }

        // Аккуратный возврат туда, откуда запустили (list view / related list)
        PageReference back = ssc.cancel();
        if(back != null){
            // Передадим параметры для показа toast на целевой странице (если там есть обработчик)
            String toastMsg = 'Successfully deleted ' + String.valueOf(deletedCount) + ' lead(s).';
            back.getParameters().put('deleteSuccess', 'true');
            back.getParameters().put('deletedCount', String.valueOf(deletedCount));
            back.getParameters().put('toastMessage', toastMsg);
            back.setRedirect(true);
        }
        return back;
    }
}