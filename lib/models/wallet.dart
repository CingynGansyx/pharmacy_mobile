class Wallet {
  final double balance;

  Wallet({this.balance = 0});

  factory Wallet.fromJson(Map<String, dynamic> json) =>
      Wallet(balance: (json['balance'] as num?)?.toDouble() ?? 0);
}
