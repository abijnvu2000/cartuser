class MercadoCreds {
  const MercadoCreds({
    required this.accessToken,
  });

  factory MercadoCreds.fromMap(Map<String, dynamic> map) {
    return MercadoCreds(accessToken: map['access_token'] ?? '');
  }

  final String accessToken;
}
