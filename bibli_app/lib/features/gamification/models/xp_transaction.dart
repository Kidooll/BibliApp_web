class XpTransaction {
  final int id;
  final String userId;
  final int xpAmount;
  final String transactionType;
  final String? description;
  final int? relatedId;
  final DateTime createdAt;

  XpTransaction({
    required this.id,
    required this.userId,
    required this.xpAmount,
    required this.transactionType,
    this.description,
    this.relatedId,
    required this.createdAt,
  });

  factory XpTransaction.fromJson(Map<String, dynamic> json) {
    return XpTransaction(
      id: json['id'],
      userId: json['user_id'],
      xpAmount: json['xp_amount'],
      transactionType: json['transaction_type'],
      description: json['description'],
      relatedId: json['related_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'xp_amount': xpAmount,
      'transaction_type': transactionType,
      'description': description,
      'related_id': relatedId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
