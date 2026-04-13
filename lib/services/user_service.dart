import '../api/api_client.dart';
import '../models/transaction.dart';
import '../models/user.dart';

class UserService {
  UserService(this._api);
  final ApiClient _api;

  Future<AppUser> get(String id) async {
    final data = await _api.get('/api/users/$id');
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<AppUser> update(
    String id, {
    String? fullName,
    String? phone,
    String? email,
    String? password,
  }) async {
    final data = await _api.put('/api/users/$id', body: {
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (password != null && password.isNotEmpty) 'password': password,
    });
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<AppTransaction> deposit(String id, double amount) async {
    final data = await _api
        .post('/api/users/$id/wallet/deposit', body: {'amount': amount});
    return AppTransaction.fromJson(data as Map<String, dynamic>);
  }

  Future<AppTransaction> withdraw(String id, double amount) async {
    final data = await _api
        .post('/api/users/$id/wallet/withdraw', body: {'amount': amount});
    return AppTransaction.fromJson(data as Map<String, dynamic>);
  }

  Future<List<AppTransaction>> transactions(String id) async {
    final data = await _api.get('/api/users/$id/transactions');
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AppTransaction.fromJson)
        .toList();
  }
}
