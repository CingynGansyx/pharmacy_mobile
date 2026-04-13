import 'wallet.dart';

enum UserRole { customer, staff }

UserRole _parseRole(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'STAFF':
      return UserRole.staff;
    case 'CUSTOMER':
    default:
      return UserRole.customer;
  }
}

String roleToApi(UserRole r) => r == UserRole.staff ? 'STAFF' : 'CUSTOMER';

class AppUser {
  final String id;
  final String username;
  final String fullName;
  final String? phone;
  final String? email;
  final Wallet wallet;
  final int bonusPoints;
  final UserRole role;

  AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    this.phone,
    this.email,
    required this.wallet,
    required this.bonusPoints,
    this.role = UserRole.customer,
  });

  bool get isStaff => role == UserRole.staff;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        username: json['username'] as String,
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        wallet: json['wallet'] == null
            ? Wallet()
            : Wallet.fromJson(json['wallet'] as Map<String, dynamic>),
        bonusPoints: (json['bonusPoints'] as num?)?.toInt() ?? 0,
        role: _parseRole(json['role'] as String?),
      );
}
