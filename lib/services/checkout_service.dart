import '../api/api_client.dart';
import '../models/transaction.dart';

class CheckoutService {
  CheckoutService(this._api);
  final ApiClient _api;

  /// [items] нь `[{barcode, quantity}]` жагсаалт.
  Future<AppTransaction> checkout({
    required String userId,
    String? branchId,
    required List<Map<String, dynamic>> items,
    double walletAmount = 0,
    int bonusPoints = 0,
    String? prescriptionId,
  }) async {
    final data = await _api.post('/api/checkout', body: {
      'userId': userId,
      if (branchId != null) 'branchId': branchId,
      'items': items,
      'walletAmount': walletAmount,
      'bonusPoints': bonusPoints,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
    });
    return AppTransaction.fromJson(data as Map<String, dynamic>);
  }
}
