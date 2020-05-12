public class AccountTransactionHelper {
    
    public static void getTransactionData(List<Account> newAccounts) {

        for(Account acc : newAccounts) {
            
            EtherscanRESTCallouts.accountTransactions(acc.Name);
        }
    }

}
