Lead leadToUpdate = [SELECT Id, Status FROM Lead WHERE Id = '00QKc000006OP5PMAW' LIMIT 1];
System.debug('Current status: ' + leadToUpdate.Status);
leadToUpdate.Status = 'DENIED';
update leadToUpdate;
System.debug('Status changed to DENIED');

// Теперь изменим на Final Denied
leadToUpdate.Status = 'Final Denied';
update leadToUpdate;
System.debug('Status changed to Final Denied'); 