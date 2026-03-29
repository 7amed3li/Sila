import 'package:sila_app/features/notifications/data/models/notification_content.dart';
import 'package:sila_app/features/notifications/data/models/notification_settings.dart';
import 'package:sila_app/features/notifications/data/models/user_activity_log.dart';

abstract class INotificationRepository {
  Future<void> seedInitialContentIfNeeded();

  Future<List<NotificationContent>> getContentByCategory(String category);
  Future<NotificationContent?> getContentByContentId(String contentId);
  Future<void> saveContent(NotificationContent content);

  Future<NotificationSettings> getSettings(String featureKey);
  Future<List<NotificationSettings>> getAllSettings({int? limit});
  Future<void> saveSettings(NotificationSettings settings);

  Future<UserActivityLog> getActivityLog(String featureKey);
  Future<void> saveActivityLog(UserActivityLog log);
}
