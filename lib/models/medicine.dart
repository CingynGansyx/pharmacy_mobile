class Medicine {
  final String barcode;
  final String name;
  final String? tag;
  final String? description;
  final double price;
  final int quantity;
  final String? manufacturer;
  final String? category;
  final DateTime? expiryDate;
  final bool prescriptionRequired;

  Medicine({
    required this.barcode,
    required this.name,
    this.tag,
    this.description,
    required this.price,
    required this.quantity,
    this.manufacturer,
    this.category,
    this.expiryDate,
    this.prescriptionRequired = false,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        barcode: json['barcode'] as String,
        name: json['name'] as String,
        tag: json['tag'] as String?,
        description: json['description'] as String?,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        manufacturer: json['manufacturer'] as String?,
        category: json['category'] as String?,
        expiryDate: json['expiryDate'] == null
            ? null
            : DateTime.tryParse(json['expiryDate'] as String),
        prescriptionRequired: json['prescriptionRequired'] as bool? ?? false,
      );

  Map<String, dynamic> toCreateJson() => {
        'barcode': barcode,
        'name': name,
        if (tag != null) 'tag': tag,
        if (description != null) 'description': description,
        'price': price,
        'quantity': quantity,
        if (manufacturer != null) 'manufacturer': manufacturer,
        if (category != null) 'category': category,
        if (expiryDate != null)
          'expiryDate':
              '${expiryDate!.year.toString().padLeft(4, '0')}-${expiryDate!.month.toString().padLeft(2, '0')}-${expiryDate!.day.toString().padLeft(2, '0')}',
        'prescriptionRequired': prescriptionRequired,
      };
}
