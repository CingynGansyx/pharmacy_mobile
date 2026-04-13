import '../api/api_client.dart';
import '../models/branch.dart';

class BranchService {
  BranchService(this._api);
  final ApiClient _api;

  Future<List<Branch>> all() async {
    final data = await _api.get('/api/branches');
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(Branch.fromJson)
        .toList();
  }

  Future<Branch> create({
    required String name,
    String? address,
    String? phone,
    String? managerName,
  }) async {
    final data = await _api.post('/api/branches', body: {
      'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (managerName != null) 'managerName': managerName,
    });
    return Branch.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _api.delete('/api/branches/$id');
}
