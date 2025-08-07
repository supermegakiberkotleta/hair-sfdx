// Простой тест отправки email
Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
mail.setToAddresses(new String[] {'test@broker.com'});
mail.setSubject('Test Email');
mail.setPlainTextBody('This is a test email from Salesforce');
System.debug('About to send test email...');
Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
System.debug('Test email sent successfully!'); 