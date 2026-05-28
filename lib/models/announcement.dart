enum AnnouncementType { news, promo, alert, info }

AnnouncementType _parseType(String? s) {
  switch ((s ?? 'NEWS').toUpperCase()) {
    case 'PROMO':
      return AnnouncementType.promo;
    case 'ALERT':
      return AnnouncementType.alert;
    case 'INFO':
      return AnnouncementType.info;
    case 'NEWS':
    default:
      return AnnouncementType.news;
  }
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final AnnouncementType type;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool pinned;
  final bool active;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.imageUrl,
    this.createdAt,
    this.expiresAt,
    this.pinned = false,
    this.active = true,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        type: _parseType(json['type'] as String?),
        imageUrl: json['imageUrl'] as String?,
        createdAt: json['createdAt'] == null
            ? null
            : DateTime.tryParse(json['createdAt'] as String),
        expiresAt: json['expiresAt'] == null
            ? null
            : DateTime.tryParse(json['expiresAt'] as String),
        pinned: json['pinned'] as bool? ?? false,
        active: json['active'] as bool? ?? true,
      );
}
