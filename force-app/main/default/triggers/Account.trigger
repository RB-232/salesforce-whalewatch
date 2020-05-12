trigger Account on Account (after insert) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            AccountTransactionHelper.getTransactionData(Trigger.new);
        }
    }
}