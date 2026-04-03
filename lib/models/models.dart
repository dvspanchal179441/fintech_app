class Bill {
  String id;
  double amount;
  bool isPaid;
  DateTime dueDate;
  DateTime? generationDate;
  String? cardId;   // Reference to SmartCard
  String? billerId; // Reference to UtilityBiller
  String? billerName; // For quick display
  
  Bill({
    required this.id,
    required this.amount,
    required this.isPaid,
    required this.dueDate,
    this.generationDate,
    this.cardId,
    this.billerId,
    this.billerName,
  });
}

class UtilityBiller {
  String id;
  String name;
  String type; // Electricity, Water, WiFi, Gas, etc.
  String accountNumber;
  
  UtilityBiller({
    required this.id,
    required this.name,
    required this.type,
    required this.accountNumber,
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
  String? cardId; // Associated card/account
  double? amount; // Storing amount for detail display
  
  ExtendedTransaction({
    required this.transactionId,
    this.note,
    this.attachmentPath,
    this.cardId,
    this.amount,
  });
}
