import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String _packageName = 'com.virelon.spent_time_focus';

  static Future<void> updateUsageWidget({
    required String usageTime,
    String status = 'Spent: Odaklandın',
  }) async {
    try {
      await HomeWidget.saveWidgetData('usage_time', usageTime);
      await HomeWidget.saveWidgetData('widget_status', status);
      await HomeWidget.updateWidget(
        androidName: 'UsageWidgetProvider',
        qualifiedAndroidName: '$_packageName.UsageWidgetProvider',
      );
    } catch (e) {
      // ignore
    }
  }

  static Future<void> updateBatteryWidget({
    required String percentage,
  }) async {
    try {
      await HomeWidget.saveWidgetData('battery_percentage', percentage);
      await HomeWidget.updateWidget(
        androidName: 'BatteryWidgetProvider',
        qualifiedAndroidName: '$_packageName.BatteryWidgetProvider',
      );
    } catch (e) {
      // ignore
    }
  }

  static Future<void> updateScrollWidget({
    required String distance,
    required String comparison,
  }) async {
    try {
      await HomeWidget.saveWidgetData('scroll_distance', distance);
      await HomeWidget.saveWidgetData('scroll_comparison', comparison);
      await HomeWidget.updateWidget(
        androidName: 'ScrollWidgetProvider',
        qualifiedAndroidName: '$_packageName.ScrollWidgetProvider',
      );
    } catch (e) {
      // ignore
    }
  }

  static Future<void> updateCalendarWidget({
    required String day,
    required String month,
    required String weekday,
  }) async {
    try {
      await HomeWidget.saveWidgetData('calendar_day', day);
      await HomeWidget.saveWidgetData('calendar_month', month);
      await HomeWidget.saveWidgetData('calendar_weekday', weekday);
      await HomeWidget.updateWidget(
        androidName: 'CalendarWidgetProvider',
        qualifiedAndroidName: '$_packageName.CalendarWidgetProvider',
      );
    } catch (e) {
      // ignore
    }
  }

  static Future<void> updatePomodoroWidget({
    required String timer,
    required String status,
    required String sessions,
  }) async {
    try {
      await HomeWidget.saveWidgetData('pomodoro_timer', timer);
      await HomeWidget.saveWidgetData('pomodoro_status', status);
      await HomeWidget.saveWidgetData('pomodoro_sessions', sessions);
      await HomeWidget.updateWidget(
        androidName: 'PomodoroWidgetProvider',
        qualifiedAndroidName: '$_packageName.PomodoroWidgetProvider',
      );
    } catch (e) {
      // ignore
    }
  }

  static Future<void> updateTopAppsWidget({
    required String app1,
    required String app2,
    required String app3,
  }) async {
    try {
      await HomeWidget.saveWidgetData('top_app_1', app1);
      await HomeWidget.saveWidgetData('top_app_2', app2);
      await HomeWidget.saveWidgetData('top_app_3', app3);
      await HomeWidget.updateWidget(
        androidName: 'TopAppsWidgetProvider',
        qualifiedAndroidName: '$_packageName.TopAppsWidgetProvider',
      );
    } catch (e) {
      // ignore
    }
  }

  static Future<void> updateBillWidget({
    required String item1,
    required String total,
  }) async {
    try {
      await HomeWidget.saveWidgetData('bill_item_1', item1);
      await HomeWidget.saveWidgetData('bill_total', total);
      await HomeWidget.updateWidget(
        androidName: 'BillWidgetProvider',
        qualifiedAndroidName: '$_packageName.BillWidgetProvider',
      );
    } catch (e) {
      // ignore
    }
  }

  static Future<void> updateDetoxWidget({
    required String status,
    required String desc,
  }) async {
    try {
      await HomeWidget.saveWidgetData('detox_status', status);
      await HomeWidget.saveWidgetData('detox_desc', desc);
      await HomeWidget.updateWidget(
        androidName: 'DetoxWidgetProvider',
        qualifiedAndroidName: '$_packageName.DetoxWidgetProvider',
      );
    } catch (e) {
      // ignore
    }
  }
}
