import '../api/api_client.dart';
import '../models/announcement.dart';

class AnnouncementService {
  AnnouncementService(this._api);
  final ApiClient _api;

  Future<List<Announcement>> activeAnnouncements() async {
    final data = await _api.get('/api/announcements', query: {'activeOnly': true});
    return (data as List)
        .whereType<Map<String, dynamic>>()
        .map(Announcement.fromJson)
        .toList();
  }

  Future<Announcement?> byId(String id) async {
    try {
      final data = await _api.get('/api/announcements/$id');
      return Announcement.fromJson(data as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
