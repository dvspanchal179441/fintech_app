class Bill {
  String id;
  double amount;
  bool isPaid;
  DateTime dueDate;
  DateTime? generationDate;
  String? cardId;   // Reference to SmartCard
  String? billerId; // Reference to UtilityBiller
  String? billerName; // For quick display
  int? billingDay; // 1-31
  int? monthGap; // 1, 2, 3, etc.
  
  Bill({
    required this.id,
    required this.amount,
    required this.isPaid,
    required this.dueDate,
    this.generationDate,
    this.cardId,
    this.billerId,
    this.billerName,
    this.billingDay,
    this.monthGap,
  });
}

class UtilityBiller {
  String id;
  String name;
  String type; // Electricity, Water, WiFi, Gas, etc.
  String accountNumber;
  int? billingDay;
  int? monthGap;
  
  UtilityBiller({
    required this.id,
    required this.name,
    required this.type,
    required this.accountNumber,
    this.billingDay,
    this.monthGap,
  });
}

class Task {
  String id;
  String title;
  DateTime scheduledTime;
  String description;
  String status; // 'pending', 'completed'

  Task({
    required this.id,
    required this.title,
    required this.scheduledTime,
    required this.description,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'scheduledTime': scheduledTime.toIso8601String(),
    'description': description,
    'status': status,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    scheduledTime: DateTime.parse(json['scheduledTime']),
    description: json['description'],
    status: json['status'],
  );
}

class Note {
  String id;
  String title;
  String content;
  DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'],
    title: json['title'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
  );
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
