import 'medicine.dart';

class CartItem {
  final Medicine medicine;
  int quantity;

  CartItem({required this.medicine, this.quantity = 1});

  double get subtotal => medicine.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        medicine: Medicine.fromJson(json['medicine'] as Map<String, dynamic>),
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );
}
