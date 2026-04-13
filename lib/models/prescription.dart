class Prescription {
  final String id;
  final String? userId;
  final String? originalFileName;
  final String? contentType;
  final int sizeBytes;
  final String? doctorName;
  final String? notes;
  final DateTime? uploadedAt;

  Prescription({
    required this.id,
    this.userId,
    this.originalFileName,
    this.contentType,
    this.sizeBytes = 0,
    this.doctorName,
    this.notes,
    this.uploadedAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) => Prescription(
        id: json['id'] as String,
        userId: json['userId'] as String?,
        originalFileName: json['originalFileName'] as String?,
        contentType: json['contentType'] as String?,
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        doctorName: json['doctorName'] as String?,
        notes: json['notes'] as String?,
        uploadedAt: json['uploadedAt'] == null
            ? null
            : DateTime.tryParse(json['uploadedAt'] as String),
      );
}
