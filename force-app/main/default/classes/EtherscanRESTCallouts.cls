public class EtherscanRESTCallouts {

    private static final API_Token__mdt apiRecord = [SELECT API_Token__c, MasterLabel FROM API_Token__mdt WHERE MasterLabel = 'Etherscan' WITH SECURITY_ENFORCED];

    private static final String SINGLE_ACCOUNT_BALANCE = 'https://api.etherscan.io/api?module=account&action=balance&' + 
                                                        'address=0xddbd2b932c763ba5b1b7ae3b362eac3e8d40121a&tag=latest&apikey=' + apiRecord.API_Token__c;
    private static final String MULTI_ACCOUNT_BALANCE = 'https://api.etherscan.io/api?module=account&action=balancemulti&' + 
                                                        'address=0xddbd2b932c763ba5b1b7ae3b362eac3e8d40121a,0x63a9975ba31b0b9626b34300f7f627147df1f526,0x198ef1ec325a96cc354c7266a038be8b5c558f67&tag=latest&apikey=' + apiRecord.API_Token__c;                                                    
                                                        
    @future(callout=true)
    public static void singleAccountBalance() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(SINGLE_ACCOUNT_BALANCE);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() == 200) {
            Object result = (Object) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> recordMap = (Map<String, Object>)result;

            String balanceString = (String) recordMap.get('result');
            balanceString = balanceString.substring(0, 6);

            Integer balance = Integer.valueOf(balanceString);

            Account accountBalance = new Account(Account_Balance__c = balance, Name='0xddbd2b932c763ba5b1b7ae3b362eac3e8d40121a');

            if(accountBalance != null) {
                try {
                    upsert accountBalance;
                } catch (DMLException e) {
                    ApexPages.addMessages(e);

                    Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
                    String[] toAddresses = new String[] {'djrdev@icloud.com'};
                    mail.setToAddresses(toAddresses);
                    mail.setReplyTo('djrdev@icloud.com');
                    mail.setSenderDisplayName('Apex error message');
                    mail.setSubject('Error from Org&nbsp;: ' + UserInfo.getOrganizationName());
                    mail.setPlainTextBody(e.getMessage());
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                }
            }

        } else {
            System.debug(response.getBody());
        }
    }
    @future(callout=true)
    public static void multiAccountBalance() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(MULTI_ACCOUNT_BALANCE);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() == 200) {
            List<Object> results = (List<Object>) JSON.deserializeUntyped(response.getBody());
            List<Account> accountsToUpsert = new List<Account>();

            for(Object result : results) {
                Map<String, Object> recordMap = (Map<String, Object>)result;

                String balanceString = (String) recordMap.get('result');
                balanceString = balanceString.substring(0, 6);

                Integer balance = Integer.valueOf(balanceString);

                Account accountBalance = new Account(Account_Balance__c = balance, Name='0xddbd2b932c763ba5b1b7ae3b362eac3e8d40121a');

                accountsToUpsert.add(accountBalance);
            }

            if(!accountsToUpsert.isEmpty()) {
                try {
                    upsert accountBalance;
                } catch (DMLException e) {
                    ApexPages.addMessages(e);

                    Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
                    String[] toAddresses = new String[] {'djrdev@icloud.com'};
                    mail.setToAddresses(toAddresses);
                    mail.setReplyTo('djrdev@icloud.com');
                    mail.setSenderDisplayName('Apex error message');
                    mail.setSubject('Error from Org&nbsp;: ' + UserInfo.getOrganizationName());
                    mail.setPlainTextBody(e.getMessage());
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                }
            }

        } else {
            System.debug(response.getBody());
        }
    }
}
