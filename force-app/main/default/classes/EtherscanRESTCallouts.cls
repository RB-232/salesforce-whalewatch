public class EtherscanRESTCallouts {                                                 

    private static Decimal toEth(String wei) {
        System.debug(wei);
        Decimal ethAmount = Decimal.valueOf(wei).divide(Math.pow(10, 18), 2, System.RoundingMode.UP);
        System.debug(ethAmount);
        return ethAmount;
    }

    @future(callout=true)
    public static void accountTransactions(Id accId, String endpoint) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() == 200) {
            
            List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        
            JSONParser parser = JSON.createParser(response.getBody());
            EtherscanJSONHelper ethInstance = new EtherscanJSONHelper(parser);

            Integer count = 1;
            for(EtherscanJSONHelper.Result result : ethInstance.result) {
                Opportunity opp = new Opportunity();

                Datetime convertedTimeStamp = Datetime.newInstance(Long.valueOf(result.timeStamp));
                Date dateFromTimeStamp = Date.newInstance(convertedTimeStamp.year(), convertedTimeStamp.month(), convertedTimeStamp.day());

                opp.Name = 'Transaction ' + count++;
                opp.CloseDate = dateFromTimeStamp;
                opp.StageName = 'Closed';
                opp.Block_Number__c = Integer.valueOf(result.blockNumber);
                opp.Time_Stamp__c = convertedTimeStamp;
                opp.Hash__c = result.hash;
                opp.Nonce__c = Integer.valueOf(result.nonce);
                opp.Block_Hash__c = result.blockHash;
                opp.Transaction_Index__c = Integer.valueOf(result.transactionIndex);
                opp.From_Address__c = result.from_Z;
                opp.To_Address__c = result.to;
                opp.Transaction_Amount__c = toEth(result.value);
                opp.Gas__c = Integer.valueOf(result.gas);
                opp.Gas_Price_in_Eth__c = toEth(result.gasPrice);
                opp.isError__c = Boolean.valueOf(result.isError);
                opp.Transaction_Rec__c = Boolean.valueOf(result.txreceipt_status);
                opp.Input__c = result.input;
                opp.Contract_Address__c = result.contractAddress;
                opp.Cumulative_Gas_Used__c = Integer.valueOf(result.cumulativeGasUsed);
                opp.Gas_Used__c = Integer.valueOf(result.gasUsed);
                opp.Confirmations__c = Integer.valueOf(result.confirmations);
                opp.AccountId = accId;

                opportunitiesToInsert.add(opp);
            }

            if(!opportunitiesToInsert.isEmpty()) {
                try {
                    insert opportunitiesToInsert;
                } catch (DMLException e) {
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
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
    // @future(callout=true)
    // public static void singleAccountBalance() {
    //     Http http = new Http();
    //     HttpRequest request = new HttpRequest();
    //     request.setEndpoint(SINGLE_ACCOUNT_BALANCE);
    //     request.setMethod('GET');
    //     request.setHeader('Content-Type', 'application/json;charset=UTF-8');
    //     HttpResponse response = http.send(request);
    //     // Parse the JSON response
    //     if (response.getStatusCode() == 200) {
    //         Object result = (Object) JSON.deserializeUntyped(response.getBody());
    //         Map<String, Object> recordMap = (Map<String, Object>)result;

    //         String balanceString = (String) recordMap.get('result');
    //         // balanceString = balanceString.substring(0, 6);

    //         Decimal ethBalance = toEth(balanceString);

    //         Account accountBalance = new Account(Account_Balance__c = ethBalance, Account_Balance_String__c = balanceString, Name='0x267f70f9b856de226fea5fc1b0a8e319c72ceff5');

    //         if(accountBalance != null) {
    //             try {
    //                 upsert accountBalance;
    //             } catch (DMLException e) {
    //                 ApexPages.addMessages(e);

    //                 Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
    //                 String[] toAddresses = new String[] {'djrdev@icloud.com'};
    //                 mail.setToAddresses(toAddresses);
    //                 mail.setReplyTo('djrdev@icloud.com');
    //                 mail.setSenderDisplayName('Apex error message');
    //                 mail.setSubject('Error from Org&nbsp;: ' + UserInfo.getOrganizationName());
    //                 mail.setPlainTextBody(e.getMessage());
    //                 Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    //             }
    //         }

    //     } else {
    //         System.debug(response.getBody());
    //     }
    // }

    // @future(callout=true)
    // public static void multiAccountBalance() {
    //     Http http = new Http();
    //     HttpRequest request = new HttpRequest();
    //     request.setEndpoint(MULTI_ACCOUNT_BALANCE);
    //     request.setMethod('GET');
    //     request.setHeader('Content-Type', 'application/json;charset=UTF-8');
    //     HttpResponse response = http.send(request);
    //     // Parse the JSON response
    //     if (response.getStatusCode() == 200) {
    //         // Hoping there is a better way to do this than using Object everywhere
    //         Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
    //         List<Object> accountBalanceList = (List<Object>) results.get('result');
    //         List<Account> accountsToUpsert = new List<Account>();

    //         for(Object result : accountBalanceList) {
    //             Map<String, Object> account = (Map<String, Object>) result;
                
    //             String balanceString = (String) account.get('balance');
    //             Decimal ethBalance = toEth(balanceString);

    //             String accountNumberString = (String) account.get('account');

    //             Account accountBalance = new Account(Account_Balance__c = ethBalance, Account_Balance_String__c = balanceString, Name=accountNumberString);

    //             accountsToUpsert.add(accountBalance);
    //         }

    //         if(!accountsToUpsert.isEmpty()) {
    //             try {
    //                 upsert accountsToUpsert;
    //             } catch (DMLException e) {
    //                 ApexPages.addMessages(e);

    //                 Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
    //                 String[] toAddresses = new String[] {'djrdev@icloud.com'};
    //                 mail.setToAddresses(toAddresses);
    //                 mail.setReplyTo('djrdev@icloud.com');
    //                 mail.setSenderDisplayName('Apex error message');
    //                 mail.setSubject('Error from Org&nbsp;: ' + UserInfo.getOrganizationName());
    //                 mail.setPlainTextBody(e.getMessage());
    //                 Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    //             }
    //         }

    //     } else {
    //         System.debug(response.getBody());
    //     }
    // }

}