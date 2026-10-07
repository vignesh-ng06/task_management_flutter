import '../../../core/api/api_client.dart';
import 'models/notification.dart';

class NotificationRepository {
  final ApiClient _api;
  NotificationRepository(this._api);

  Future<List<AppNotification>> getAll() async {
    final data = await _api.get('/notifications');
    final list = (data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(AppNotification.fromJson).toList();
  }

  Future<int> getUnreadCount() async {
    final data = await _api.get('/notifications/unread-count');
    return (data['unread'] as num).toInt();
  }

  Future<AppNotification> markAsRead(int id) async {
    final data = await _api.patch('/notifications/$id/read', {});
    return AppNotification.fromJson(data);
  }

  Future<int> markAllAsRead() async {
    final data = await _api.patch('/notifications/read-all', {});
    return (data['updated'] as num).toInt();
  }

  Future<void> delete(int id) async {
    await _api.delete('/notifications/$id');
  }
}