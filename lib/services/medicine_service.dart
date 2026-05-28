import '../api/api_client.dart';
import '../models/medicine.dart';
import '../models/paginated.dart';

class MedicineService {
  MedicineService(this._api);
  final ApiClient _api;

  /// Paginated + filtered list. Backend returns {items, page, size, totalItems, totalPages}.
  Future<PaginatedMedicines> allPaginated({
    String? q,
    String? category,
    String? manufacturer,
    String? atcCode,
    String? innName,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? prescriptionRequired,
    bool? hasInsurance,
    String sort = 'name',
    String order = 'asc',
    int page = 1,
    int size = 20,
  }) async {
    final data = await _api.get('/api/medicines', query: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (category != null) 'category': category,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (atcCode != null) 'atcCode': atcCode,
      if (innName != null) 'innName': innName,
      if (minPrice != null) 'minPrice': minPrice,
      if (maxPrice != null) 'maxPrice': maxPrice,
      if (inStock != null) 'inStock': inStock,
      if (prescriptionRequired != null)
        'prescriptionRequired': prescriptionRequired,
      if (hasInsurance != null) 'hasInsurance': hasInsurance,
      'sort': sort,
      'order': order,
      'page': page,
      'size': size,
    });
    return PaginatedMedicines.fromJson(data as Map<String, dynamic>);
  }

  /// Convenience: fetch all items (first page with large size).
  Future<List<Medicine>> all() async {
    final result = await allPaginated(size: 1000);
    return result.items;
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

  /// Excel файлаар эмийн бүртгэл импортлох.
  Future<ExcelImportResult> importExcel({
    required String fileName,
    required List<int> fileBytes,
  }) async {
    final data = await _api.postMultipart(
      '/api/medicines/import',
      fields: {},
      fileFieldName: 'file',
      fileName: fileName,
      fileBytes: fileBytes,
      fileContentType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    return ExcelImportResult.fromJson(data as Map<String, dynamic>);
  }
}
