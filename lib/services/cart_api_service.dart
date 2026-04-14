import '../api/api_client.dart';
import '../models/server_cart.dart';

class CartApiService {
  CartApiService(this._api);
  final ApiClient _api;

  Future<ServerCart> get(String userId) async {
    final data = await _api.get('/api/cart/$userId');
    return ServerCart.fromJson(data as Map<String, dynamic>);
  }

  Future<ServerCart> addItem(String userId, String barcode,
      {int quantity = 1}) async {
    final data = await _api.post('/api/cart/$userId/items', body: {
      'barcode': barcode,
      'quantity': quantity,
    });
    return ServerCart.fromJson(data as Map<String, dynamic>);
  }

  Future<ServerCart> updateItem(
      String userId, String barcode, int quantity) async {
    final data = await _api.put('/api/cart/$userId/items/$barcode', body: {
      'quantity': quantity,
    });
    return ServerCart.fromJson(data as Map<String, dynamic>);
  }

  Future<ServerCart> removeItem(String userId, String barcode) async {
    await _api.delete('/api/cart/$userId/items/$barcode');
    return get(userId);
  }

  Future<ServerCart> clear(String userId) async {
    await _api.delete('/api/cart/$userId');
    return get(userId);
  }
}
