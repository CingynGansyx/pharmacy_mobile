class Branch {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? managerName;

  Branch({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.managerName,
  });

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        managerName: json['managerName'] as String?,
      );
}
