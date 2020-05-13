public class EtherscanJSONHelper {
    public String status;
    public String message;
    public TransactionJSON[] result;

    public class TransactionJSON {
        public String blockNumber;
        public String timeStamp;
        public String hash;
        public String nonce;
        public String blockHash;
        public String transactionIndex;
        public String from;
        public String to;
        public String value;
        public String gasPrice;
        public String isError;
        public String txreceipt_status;
        public String input;
        public String contractAddress;
        public String cumulativeGasUsed;
        public String gasUsed;
        public String confirmations;
    }
}
