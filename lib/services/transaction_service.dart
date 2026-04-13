import '../api/api_client.dart';
import '../models/transaction.dart';

class TransactionService {
  TransactionService(this._api);
  final ApiClient _api;

  Future<List<AppTransaction>> all() => _list('/api/transactions');
  Future<List<AppTransaction>> sales() => _list('/api/transactions/sales');
  Future<List<AppTransaction>> purchases() =>
      _list('/api/transactions/purchases');

  Future<Map<String, double>> summary() async {
    final data = await _api.get('/api/transactions/summary');
    final map = (data as Map<String, dynamic>);
    return map.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<List<AppTransaction>> _list(String path) async {
    final data = await _api.get(path);
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(AppTransaction.fromJson)
        .toList();
  }
}
