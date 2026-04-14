import '../api/api_client.dart';
import '../models/payment.dart';

class PaymentApiService {
  PaymentApiService(this._api);
  final ApiClient _api;

  Future<Payment> create({
    required String transactionId,
    required String userId,
    required PaymentMethod method,
    required double amount,
  }) async {
    final data = await _api.post('/api/payments', body: {
      'transactionId': transactionId,
      'userId': userId,
      'method': paymentMethodToApi(method),
      'amount': amount,
    });
    return Payment.fromJson(data as Map<String, dynamic>);
  }

  Future<Payment> confirm(String paymentId) async {
    final data = await _api.post('/api/payments/$paymentId/confirm');
    return Payment.fromJson(data as Map<String, dynamic>);
  }

  Future<Payment?> find(String paymentId) async {
    try {
      final data = await _api.get('/api/payments/$paymentId');
      return Payment.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<Payment>> byUser(String userId) async {
    final data = await _api.get('/api/payments/user/$userId');
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(Payment.fromJson)
        .toList();
  }

  Future<List<Payment>> byTransaction(String transactionId) async {
    final data =
        await _api.get('/api/payments/transaction/$transactionId');
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(Payment.fromJson)
        .toList();
  }
}
