class BeneficiaryModel {
  final String id;
  final String name;
  final String accountNumber;
  final String bankName;
  final String initials;
  final String? imageUrl; // For optional avatar display

  BeneficiaryModel({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.bankName,
    required this.initials,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accountNumber': accountNumber,
      'bankName': bankName,
      'initials': initials,
      'imageUrl': imageUrl,
    };
  }

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) {
    return BeneficiaryModel(
      id: json['id'],
      name: json['name'],
      accountNumber: json['accountNumber'],
      bankName: json['bankName'],
      initials: json['initials'],
      imageUrl: json['imageUrl'],
    );
  }
}
