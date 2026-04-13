import '../api/api_client.dart';
import '../models/medicine.dart';

class MedicineService {
  MedicineService(this._api);
  final ApiClient _api;

  Future<List<Medicine>> all() async {
    final data = await _api.get('/api/medicines');
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(Medicine.fromJson)
        .toList();
  }

  Future<List<Medicine>> search(String q) async {
    final data = await _api.get('/api/medicines/search', query: {'q': q});
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(Medicine.fromJson)
        .toList();
  }

  Future<Medicine?> byBarcode(String barcode) async {
    try {
      final data = await _api.get('/api/medicines/$barcode');
      return Medicine.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<Medicine> create(Medicine m) async {
    final data = await _api.post('/api/medicines', body: m.toCreateJson());
    return Medicine.fromJson(data as Map<String, dynamic>);
  }

  Future<Medicine> addStock(String barcode, int amount) async {
    final data = await _api
        .post('/api/medicines/$barcode/stock', body: {'amount': amount});
    return Medicine.fromJson(data as Map<String, dynamic>);
  }
}
