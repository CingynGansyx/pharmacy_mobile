import 'cart_item.dart';

enum TxType { sale, purchase, walletDeposit, walletWithdraw, unknown }

TxType _parseType(String? s) {
  switch (s) {
    case 'SALE':
      return TxType.sale;
    case 'PURCHASE':
      return TxType.purchase;
    case 'WALLET_DEPOSIT':
      return TxType.walletDeposit;
    case 'WALLET_WITHDRAW':
      return TxType.walletWithdraw;
    default:
      return TxType.unknown;
  }
}

class AppTransaction {
  final String id;
  final TxType type;
  final String? userId;
  final String? branchId;
  final List<CartItem> items;
  final double total;
  final int bonusEarned;
  final int bonusUsed;
  final double walletUsed;
  final DateTime? dateTime;

  AppTransaction({
    required this.id,
    required this.type,
    this.userId,
    this.branchId,
    required this.items,
    required this.total,
    required this.bonusEarned,
    required this.bonusUsed,
    required this.walletUsed,
    this.dateTime,
  });

  double get cashPaid => total - bonusUsed - walletUsed;

  factory AppTransaction.fromJson(Map<String, dynamic> json) => AppTransaction(
        id: json['id'] as String,
        type: _parseType(json['type'] as String?),
        userId: json['userId'] as String?,
        branchId: json['branchId'] as String?,
        items: ((json['items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CartItem.fromJson)
            .toList(),
        total: (json['total'] as num?)?.toDouble() ?? 0,
        bonusEarned: (json['bonusEarned'] as num?)?.toInt() ?? 0,
        bonusUsed: (json['bonusUsed'] as num?)?.toInt() ?? 0,
        walletUsed: (json['walletUsed'] as num?)?.toDouble() ?? 0,
        dateTime: json['dateTime'] == null
            ? null
            : DateTime.tryParse(json['dateTime'] as String),
      );
}
