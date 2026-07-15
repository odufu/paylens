enum TransactionCategory {
  transfers,
  bills,
  wallet,
}

enum TransactionStatus {
  success,
  pending,
  failed,
}

class TransactionModel {
  final String id;
  final String title;
  final String subtitle;
  final double amount; // Positive for credit/funding, negative for debit/payments
  final DateTime date;
  final TransactionCategory category;
  final TransactionStatus status;
  final String reference;
  final String provider; // "Paystack" or "VTPass"
  final String? vendorReference;

  TransactionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.category,
    required this.status,
    required this.reference,
    required this.provider,
    this.vendorReference,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.name,
      'status': status.name,
      'reference': reference,
      'provider': provider,
      if (vendorReference != null) 'vendor_reference': vendorReference,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      title: json['title'],
      subtitle: json['subtitle'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      category: TransactionCategory.values.firstWhere((e) => e.name == json['category']),
      status: TransactionStatus.values.firstWhere((e) => e.name == json['status']),
      reference: json['reference'],
      provider: json['provider'],
      vendorReference: json['vendor_reference'] ?? json['vendorReference'],
    );
  }
}
