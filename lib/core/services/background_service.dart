import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'limit_service.dart';
import 'usage_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Limitleri getir
      final limits = await LimitService.getLimits();
      if (limits.isEmpty) return true;

      // Bugünkü kullanımı getir
      final todayUsage = await UsageService.getTodayAppList();
      final Map<String, Duration> usageMap = {
        for (var app in todayUsage) app.packageName: app.usage
      };

      for (var limit in limits) {
        final currentUsage = usageMap[limit.packageName] ?? Duration.zero;
        final limitDuration = Duration(minutes: limit.limitMinutes);
        
        final remainingMinutes = limitDuration.inMinutes - currentUsage.inMinutes;

        if (remainingMinutes <= 0) {
          // Limit doldu
          await NotificationService.showLimitReached(appName: limit.appName);
        } else if (remainingMinutes <= 5) {
          // 5 dakika veya daha az kaldı
          await NotificationService.showLimitWarning(
            appName: limit.appName,
            remainingMinutes: remainingMinutes,
          );
        }
      }
    } catch (e) {
      // ignore
    }
    return true;
  });
}

class BackgroundService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static Future<void> startUsageCheck() async {
    await Workmanager().registerPeriodicTask(
      "usage_limit_check",
      "checkUsageLimits",
      frequency: const Duration(minutes: 15), // Android kısıtlaması nedeniyle minimum 15 dk
      constraints: Constraints(
        networkType: NetworkType.not_required,
      ),
    );
  }
}
