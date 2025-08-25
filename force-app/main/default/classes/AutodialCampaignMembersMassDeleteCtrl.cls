public with sharing class AutodialCampaignMembersMassDeleteCtrl {
    private ApexPages.StandardSetController ssc;

    public AutodialCampaignMembersMassDeleteCtrl(ApexPages.StandardSetController ssc){
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

        try {
            // Лучше перечитать записи SOQL'ом: так исключим случайные read-only экземпляры
            List<Autodial_CampaignMembers__c> toDelete =
                [SELECT Id FROM Autodial_CampaignMembers__c WHERE Id IN :ids];

            // DML (за один вызов можно до 10k; пользователи обычно отмечают не больше пары тысяч)
            delete toDelete;

            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.CONFIRM,
                toDelete.size() + ' entry(s) removed.'
            ));
        } catch (DmlException e){
            ApexPages.addMessages(e);
            return null;
        }

        // Аккуратный возврат туда, откуда запустили (list view / related list)
        PageReference back = ssc.cancel();
        if(back != null) back.setRedirect(true);
        return back;
    }
}
