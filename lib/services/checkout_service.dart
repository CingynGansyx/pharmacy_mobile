import '../api/api_client.dart';
import '../models/cart_item.dart';
import '../models/transaction.dart';

class CheckoutService {
  CheckoutService(this._api);
  final ApiClient _api;

  Future<AppTransaction> checkout({
    required String userId,
    String? branchId,
    required List<CartItem> items,
    double walletAmount = 0,
    int bonusPoints = 0,
    String? prescriptionId,
  }) async {
    final data = await _api.post('/api/checkout', body: {
      'userId': userId,
      if (branchId != null) 'branchId': branchId,
      'items': items
          .map((i) => {
                'barcode': i.medicine.barcode,
                'quantity': i.quantity,
              })
          .toList(),
      'walletAmount': walletAmount,
      'bonusPoints': bonusPoints,
      if (prescriptionId != null) 'prescriptionId': prescriptionId,
    });
    return AppTransaction.fromJson(data as Map<String, dynamic>);
  }
}
