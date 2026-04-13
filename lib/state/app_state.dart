import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/cart_item.dart';
import '../models/medicine.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';
import '../services/checkout_service.dart';
import '../services/medicine_service.dart';
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
  }

  final ApiClient api;
  late final AuthService auth;
  late final UserService users;
  late final MedicineService medicines;
  late final BranchService branches;
  late final CheckoutService checkout;
  late final TransactionService transactions;
  late final PrescriptionService prescriptions;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  final List<CartItem> _cart = [];
  List<CartItem> get cart => List.unmodifiable(_cart);
  int get cartCount => _cart.fold(0, (a, b) => a + b.quantity);
  double get cartTotal => _cart.fold(0, (a, b) => a + b.subtotal);

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
    _cart.clear();
    notifyListeners();
  }

  void addToCart(Medicine m, {int quantity = 1}) {
    final existing = _cart.indexWhere((c) => c.medicine.barcode == m.barcode);
    if (existing >= 0) {
      _cart[existing].quantity += quantity;
    } else {
      _cart.add(CartItem(medicine: m, quantity: quantity));
    }
    notifyListeners();
  }

  void setCartQuantity(String barcode, int quantity) {
    final idx = _cart.indexWhere((c) => c.medicine.barcode == barcode);
    if (idx < 0) return;
    if (quantity <= 0) {
      _cart.removeAt(idx);
    } else {
      _cart[idx].quantity = quantity;
    }
    notifyListeners();
  }

  void removeFromCart(String barcode) {
    _cart.removeWhere((c) => c.medicine.barcode == barcode);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }
}
