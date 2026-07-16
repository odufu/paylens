class BudgetModel {
  final String id;
  final String profileId;
  final String title;
  final double amount;
  final String serviceType; // 'Data', 'Cable TV', 'Electricity', 'Betting', 'WAEC', 'JAMB'
  final String? providerName;
  final String? target;
  final String? variationCode;
  final bool isAutomatic;
  final String frequency; // 'one_time', 'daily', 'weekly', 'monthly'
  final DateTime? nextRunDate;
  final String status; // 'active', 'completed', 'cancelled'
  final double? subscriptionCost;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.profileId,
    required this.title,
    required this.amount,
    required this.serviceType,
    this.providerName,
    this.target,
    this.variationCode,
    required this.isAutomatic,
    required this.frequency,
    this.nextRunDate,
    required this.status,
    this.subscriptionCost,
    required this.createdAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      serviceType: json['service_type'] as String,
      providerName: json['provider_name'] as String?,
      target: json['target'] as String?,
      variationCode: json['variation_code'] as String?,
      isAutomatic: json['is_automatic'] as bool? ?? false,
      frequency: json['frequency'] as String? ?? 'one_time',
      nextRunDate: json['next_run_date'] != null ? DateTime.parse(json['next_run_date'] as String) : null,
      status: json['status'] as String? ?? 'active',
      subscriptionCost: json['subscription_cost'] != null ? (json['subscription_cost'] as num).toDouble() : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'title': title,
      'amount': amount,
      'service_type': serviceType,
      'provider_name': providerName,
      'target': target,
      'variation_code': variationCode,
      'is_automatic': isAutomatic,
      'frequency': frequency,
      'next_run_date': nextRunDate?.toIso8601String(),
      'status': status,
      'subscription_cost': subscriptionCost,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
