import '../api/api_client.dart';
import '../models/prescription.dart';

class PrescriptionService {
  PrescriptionService(this._api);
  final ApiClient _api;

  Future<List<Prescription>> all() async {
    final data = await _api.get('/api/prescriptions');
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(Prescription.fromJson)
        .toList();
  }

  Future<Prescription> upload({
    required String userId,
    required String fileName,
    required List<int> fileBytes,
    String? contentType,
    String? doctorName,
    String? notes,
  }) async {
    final data = await _api.postMultipart(
      '/api/prescriptions',
      fields: {
        'userId': userId,
        if (doctorName != null && doctorName.isNotEmpty) 'doctorName': doctorName,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      fileFieldName: 'file',
      fileName: fileName,
      fileBytes: fileBytes,
      fileContentType: contentType,
    );
    return Prescription.fromJson(data as Map<String, dynamic>);
  }

  /// Хэрэглэгчийн жорын жагсаалтыг user id-р шүүнэ.
  Future<List<Prescription>> byUser(String userId) async {
    final list = await all();
    return list.where((p) => p.userId == userId).toList();
  }
}
