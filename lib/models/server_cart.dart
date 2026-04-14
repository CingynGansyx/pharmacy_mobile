class CartEntry {
  final String barcode;
  final String name;
  final double price;
  int quantity;

  CartEntry({
    required this.barcode,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory CartEntry.fromJson(Map<String, dynamic> json) => CartEntry(
        barcode: json['barcode'] as String,
        name: json['name'] as String,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      );
}

class ServerCart {
  final String userId;
  final List<CartEntry> items;
  final DateTime? updatedAt;

  ServerCart({
    required this.userId,
    required this.items,
    this.updatedAt,
  });

  int get count => items.fold(0, (a, b) => a + b.quantity);
  double get total => items.fold(0, (a, b) => a + b.subtotal);
  bool get isEmpty => items.isEmpty;

  factory ServerCart.fromJson(Map<String, dynamic> json) => ServerCart(
        userId: json['userId'] as String? ?? '',
        items: ((json['items'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CartEntry.fromJson)
            .toList(),
        updatedAt: json['updatedAt'] == null
            ? null
            : DateTime.tryParse(json['updatedAt'] as String),
      );
}
