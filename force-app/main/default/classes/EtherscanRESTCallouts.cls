public class EtherscanRESTCallouts {

    private static String accountAddress;

    private static final API_Token__mdt API_RECORD = [SELECT API_Token__c, MasterLabel FROM API_Token__mdt WHERE MasterLabel = 'Etherscan' WITH SECURITY_ENFORCED];

    private static final String SINGLE_ACCOUNT_BALANCE = 'https://api.etherscan.io/api?module=account&action=balance&' + 
                                                        'address=0x267f70f9b856de226fea5fc1b0a8e319c72ceff5&tag=latest&apikey=' + API_RECORD.API_Token__c;
    private static final String MULTI_ACCOUNT_BALANCE = 'https://api.etherscan.io/api?module=account&action=balancemulti&' + 
                                                        'address=0x267f70f9b856de226fea5fc1b0a8e319c72ceff5,0x1b3cb81e51011b549d78bf720b0d924ac763a7c2,0x73bceb1cd57c711feac4224d062b0f6ff338501e&tag=latest&apikey=' + API_RECORD.API_Token__c;                                                    
    private static final String ACCOUNT_TRANSACTIONS = 'https://api.etherscan.io/api?module=account&action=txlist&' + 
                                                        'address=' + accountAddress + '&startblock=0&endblock=99999999&sort=asc&apikey=' + API_RECORD.API_Token__c;                                                    

    private static Decimal toEth(String wei) {
        Decimal ethAmount = Decimal.valueOf(wei).divide(10^18, 2, System.RoundingMode.UP);

        return ethAmount;
    }

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
            // balanceString = balanceString.substring(0, 6);

            Decimal ethBalance = toEth(balanceString);

            Account accountBalance = new Account(Account_Balance__c = ethBalance, Account_Balance_String__c = balanceString, Name='0x267f70f9b856de226fea5fc1b0a8e319c72ceff5');

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
            // Hoping there is a better way to do this than using Object everywhere
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> accountBalanceList = (List<Object>) results.get('result');
            List<Account> accountsToUpsert = new List<Account>();

            for(Object result : accountBalanceList) {
                Map<String, Object> account = (Map<String, Object>) result;
                
                String balanceString = (String) account.get('balance');
                Decimal ethBalance = toEth(balanceString);

                String accountNumberString = (String) account.get('account');

                Account accountBalance = new Account(Account_Balance__c = ethBalance, Account_Balance_String__c = balanceString, Name=accountNumberString);

                accountsToUpsert.add(accountBalance);
            }

            if(!accountsToUpsert.isEmpty()) {
                try {
                    upsert accountsToUpsert;
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
    public static void accountTransactions(String accountNumber) {
        accountAddress = accountNumber;
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ACCOUNT_TRANSACTIONS);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() == 200) {
            // Hoping there is a better way to do this than using Object everywhere
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> accountTransactionList = (List<Object>) results.get('result');
            List<Opportunity> opportunitiesToInsert = new List<Opportunity>();

            for(Object result : accountTransactionList) {
                Map<String, String> account = (Map<String, String>) result;
                Opportunity opp = new Opportunity();
                
                opp.Block_Number__c = (Integer) Integer.valueOf(account.get('blockNumber'));
                opp.Time_Stamp__c = (Datetime) Datetime.newInstance(Long.valueOf(account.get('timeStamp')));
                opp.Hash__c = (String) account.get('hash');
                opp.Nonce__c = (Integer) Integer.valueOf(account.get('nonce'));
                opp.Block_Hash__c = (String) account.get('blockHash');
                opp.Transaction_Index__c = (Integer) Integer.valueOf(account.get('nonce'));
                opp.From_Address__c = (String) account.get('from');
                opp.To_Address__c = (String) account.get('to');
                opp.Transaction_Amount__c = (Decimal) toEth(account.get('value'));
                opp.Gas_Price_in_Eth__c = (Decimal) toEth(account.get('gasPrice'));
                opp.isError__c = (Boolean) Boolean.valueOf(account.get('isError'));
                opp.Transaction_Receipt_Status__c = (Boolean) Boolean.valueOf(account.get('txreceipt_status'));
                opp.Input__c = (String) account.get('input');
                opp.Contract_Address__c = (String) account.get('contractAddress');
                opp.Cumulative_Gas_Used__c = (Integer) Integer.valueOf(account.get('cumulativeGasUsed'));
                opp.Gas_Used__c = (Integer) Integer.valueOf(account.get('gasUsed'));
                opp.Confirmations__c = (Integer) Integer.valueOf(account.get('confirmations'));

                opportunitiesToInsert.add(opp);
            }

            if(!opportunitiesToInsert.isEmpty()) {
                try {
                    insert opportunitiesToInsert;
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
