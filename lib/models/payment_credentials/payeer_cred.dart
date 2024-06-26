class PayeerCred {
  const PayeerCred({
    required this.merchantId,
    required this.secretKey,
  });

  factory PayeerCred.fromMap(Map<String, dynamic> map) {
    return PayeerCred(
      merchantId: map['merchant_id'] ?? '',
      secretKey: map['secret_key'] ?? '',
    );
  }

  final String merchantId;
  final String secretKey;
}
