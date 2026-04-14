import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/server_cart.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';
import '../services/cart_api_service.dart';
import '../services/checkout_service.dart';
import '../services/medicine_service.dart';
import '../services/payment_service.dart';
import '../services/prescription_service.dart';
import '../services/transaction_service.dart';
import '../services/user_service.dart';

class AppState extends ChangeNotifier {
  AppState({ApiClient? api}) : api = api ?? ApiClient() {
    auth = AuthService(this.api);
    users = UserService(this.api);
    medicines = MedicineService(this.api);
    branches = BranchService(this.api);
    checkout = CheckoutService(this.api);
    transactions = TransactionService(this.api);
    prescriptions = PrescriptionService(this.api);
    cartApi = CartApiService(this.api);
    payments = PaymentApiService(this.api);
  }

  final ApiClient api;
  late final AuthService auth;
  late final UserService users;
  late final MedicineService medicines;
  late final BranchService branches;
  late final CheckoutService checkout;
  late final TransactionService transactions;
  late final PrescriptionService prescriptions;
  late final CartApiService cartApi;
  late final PaymentApiService payments;

  // ---- User ----
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  void setUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> refreshCurrentUser() async {
    final id = _currentUser?.id;
    if (id == null) return;
    _currentUser = await users.get(id);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _cart = null;
    notifyListeners();
  }

  // ---- Server Cart ----
  ServerCart? _cart;
  ServerCart? get cart => _cart;
  int get cartCount => _cart?.count ?? 0;
  double get cartTotal => _cart?.total ?? 0;
  bool get cartEmpty => _cart == null || _cart!.isEmpty;

  Future<void> loadCart() async {
    final id = _currentUser?.id;
    if (id == null) return;
    _cart = await cartApi.get(id);
    notifyListeners();
  }

  Future<void> addToCart(String barcode, {int quantity = 1}) async {
    final id = _currentUser?.id;
    if (id == null) return;
    _cart = await cartApi.addItem(id, barcode, quantity: quantity);
    notifyListeners();
  }

  Future<void> updateCartItem(String barcode, int quantity) async {
    final id = _currentUser?.id;
    if (id == null) return;
    _cart = await cartApi.updateItem(id, barcode, quantity);
    notifyListeners();
  }

  Future<void> removeCartItem(String barcode) async {
    final id = _currentUser?.id;
    if (id == null) return;
    _cart = await cartApi.removeItem(id, barcode);
    notifyListeners();
  }

  Future<void> clearCart() async {
    final id = _currentUser?.id;
    if (id == null) return;
    _cart = await cartApi.clear(id);
    notifyListeners();
  }
}
