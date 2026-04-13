import '../api/api_client.dart';
import '../models/user.dart';

class AuthService {
  AuthService(this._api);
  final ApiClient _api;

  Future<AppUser> login(String username, String password) async {
    final data = await _api.post('/api/auth/login', body: {
      'username': username,
      'password': password,
    });
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String fullName,
    String? phone,
    String? email,
    UserRole role = UserRole.customer,
  }) async {
    final data = await _api.post('/api/auth/register', body: {
      'username': username,
      'password': password,
      'fullName': fullName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      'role': roleToApi(role),
    });
    return AppUser.fromJson(data as Map<String, dynamic>);
  }
}
