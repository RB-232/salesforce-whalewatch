public class AccountTriggerCache {
    public static final API_Token__mdt API_RECORD = [SELECT API_Token__c, MasterLabel FROM API_Token__mdt WHERE MasterLabel = 'Etherscan' WITH SECURITY_ENFORCED]; 
}