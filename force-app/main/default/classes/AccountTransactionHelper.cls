public class AccountTransactionHelper {

    public static void getTransactionData(List<Account> newAccounts) {
        API_Token__mdt cachedAPIToken = AccountTriggerCache.API_RECORD;
        for(Account acc : newAccounts) {
            String accountTrans = 'https://api.etherscan.io/api?module=account&action=txlist&' + 
                                'address=' + acc.Name + '&startblock=0&endblock=99999999&sort=asc&apikey=' + cachedAPIToken.API_Token__c;
            
            EtherscanRESTCallouts.accountTransactions(acc.Id, accountTrans);
        }
    }

}
