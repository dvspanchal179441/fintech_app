class Bill {
  String id;
  double amount;
  bool isPaid;
  DateTime dueDate;
  DateTime? generationDate;
  
  Bill({
    required this.id,
    required this.amount,
    required this.isPaid,
    required this.dueDate,
    this.generationDate,
  });
}

/// Represents the "Gift Card Vault" data structure for Amazon, Flipkart, etc.
class GiftCard {
  String id;
  String provider; 
  String claimCode;
  double balance;
  DateTime expiryDate;

  GiftCard({
    required this.id,
    required this.provider,
    required this.claimCode,
    required this.balance,
    required this.expiryDate,
  });
}

/// Extension of a generic Transaction extending it with Notes and Attachments
class ExtendedTransaction {
  String transactionId;
  String? note; // Manual sticky notes
  String? attachmentPath; // Local path to Physical receipt image / photos
  
  ExtendedTransaction({
    required this.transactionId,
    this.note,
    this.attachmentPath,
  });
}
