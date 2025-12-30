import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _sleepKey = 'settings_sleep_hours';
  static const String _workKey = 'settings_work_hours';
  static const String _setupDoneKey = 'settings_setup_done';
  static const String _goalKey = 'settings_daily_goal';

  /// Uyku süresini getir (varsayılan 8)
  static Future<double> getSleepHours() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_sleepKey) ?? 8.0;
  }

  /// İş süresini getir (varsayılan 8)
  static Future<double> getWorkHours() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_workKey) ?? 8.0;
  }

  /// Günlük kullanım hedefini getir (varsayılan 4 saat)
  static Future<double> getDailyGoalHours() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_goalKey) ?? 4.0;
  }

  /// Ayarların yapılıp yapılmadığını kontrol et
  static Future<bool> isSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupDoneKey) ?? false;
  }

  /// Ayarları kaydet
  static Future<void> saveRoutineSettings(double sleep, double work, {double? goal}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sleepKey, sleep);
    await prefs.setDouble(_workKey, work);
    if (goal != null) {
      await prefs.setDouble(_goalKey, goal);
    }
    await prefs.setBool(_setupDoneKey, true);
  }

  /// Sadece kurulum tamamlandı flag'ini set et
  static Future<void> setSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupDoneKey, true);
  }
}
