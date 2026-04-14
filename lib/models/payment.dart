enum PaymentMethod { cash, wallet, bankTransfer, qpay }

PaymentMethod parsePaymentMethod(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'CASH':
      return PaymentMethod.cash;
    case 'WALLET':
      return PaymentMethod.wallet;
    case 'BANK_TRANSFER':
      return PaymentMethod.bankTransfer;
    case 'QPAY':
      return PaymentMethod.qpay;
    default:
      return PaymentMethod.cash;
  }
}

String paymentMethodToApi(PaymentMethod m) {
  switch (m) {
    case PaymentMethod.cash:
      return 'CASH';
    case PaymentMethod.wallet:
      return 'WALLET';
    case PaymentMethod.bankTransfer:
      return 'BANK_TRANSFER';
    case PaymentMethod.qpay:
      return 'QPAY';
  }
}

String paymentMethodLabel(PaymentMethod m) {
  switch (m) {
    case PaymentMethod.cash:
      return 'Бэлнээр';
    case PaymentMethod.wallet:
      return 'Хэтэвч';
    case PaymentMethod.bankTransfer:
      return 'Дансны шилжүүлэг';
    case PaymentMethod.qpay:
      return 'QPay';
  }
}

enum PaymentStatus { pending, confirmed, failed, expired }

PaymentStatus parsePaymentStatus(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'CONFIRMED':
      return PaymentStatus.confirmed;
    case 'FAILED':
      return PaymentStatus.failed;
    case 'EXPIRED':
      return PaymentStatus.expired;
    case 'PENDING':
    default:
      return PaymentStatus.pending;
  }
}

class Payment {
  final String id;
  final String? transactionId;
  final String? userId;
  final PaymentMethod method;
  final PaymentStatus status;
  final double amount;
  final String? qrCodeData;
  final String? bankAccount;
  final String? bankName;
  final String? referenceNote;
  final DateTime? createdAt;
  final DateTime? confirmedAt;

  Payment({
    required this.id,
    this.transactionId,
    this.userId,
    required this.method,
    required this.status,
    required this.amount,
    this.qrCodeData,
    this.bankAccount,
    this.bankName,
    this.referenceNote,
    this.createdAt,
    this.confirmedAt,
  });

  bool get isPending => status == PaymentStatus.pending;
  bool get isConfirmed => status == PaymentStatus.confirmed;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        transactionId: json['transactionId'] as String?,
        userId: json['userId'] as String?,
        method: parsePaymentMethod(json['method'] as String?),
        status: parsePaymentStatus(json['status'] as String?),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        qrCodeData: json['qrCodeData'] as String?,
        bankAccount: json['bankAccount'] as String?,
        bankName: json['bankName'] as String?,
        referenceNote: json['referenceNote'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'] as String),
        confirmedAt: json['confirmedAt'] == null
            ? null
            : DateTime.tryParse(json['confirmedAt'] as String),
      );
}
