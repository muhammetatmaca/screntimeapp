import 'dart:ui';

/// App usage data models
class AppUsageData {
  final String appName;
  final String iconType; // 'instagram', 'youtube', 'twitter', etc.
  final Duration usageTime;
  final Duration limitTime;
  final Color? gradientStart;
  final Color? gradientEnd;
  final Color? solidColor;

  const AppUsageData({
    required this.appName,
    required this.iconType,
    required this.usageTime,
    required this.limitTime,
    this.gradientStart,
    this.gradientEnd,
    this.solidColor,
  });

  /// Percentage of limit used (0.0 - 1.0+)
  double get usagePercentage => usageTime.inMinutes / limitTime.inMinutes;
  
  /// Whether limit is exceeded
  bool get isOverLimit => usageTime > limitTime;
  
  /// Remaining time (can be negative if over limit)
  Duration get remainingTime => limitTime - usageTime;
  
  /// Debt time (only if over limit)
  Duration get debtTime => isOverLimit ? usageTime - limitTime : Duration.zero;

  /// Format duration as "Xs Yd" (hours and minutes in Turkish)
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0 && minutes > 0) {
      return '${hours}s ${minutes}d';
    } else if (hours > 0) {
      return '${hours}s';
    } else {
      return '${minutes}d';
    }
  }
}

/// Daily usage data for chart
class DailyUsageData {
  final String dayLabel;
  final Duration usageTime;
  final Duration? limitTime;
  final bool isSelected;
  final bool isOverLimit;

  const DailyUsageData({
    required this.dayLabel,
    required this.usageTime,
    this.limitTime,
    this.isSelected = false,
    this.isOverLimit = false,
  });
}

/// Sample data for testing
class HomeData {
  static Duration get todayTotalUsage => const Duration(hours: 6, minutes: 14);
  static Duration get dailyLimit => const Duration(hours: 5, minutes: 30);
  static Duration get overLimitTime => todayTotalUsage - dailyLimit;
  
  static List<DailyUsageData> get weeklyData => [
    const DailyUsageData(dayLabel: 'Pzt', usageTime: Duration(hours: 4, minutes: 30)),
    const DailyUsageData(dayLabel: 'Sal', usageTime: Duration(hours: 3, minutes: 0)),
    const DailyUsageData(dayLabel: 'Çar', usageTime: Duration(hours: 5, minutes: 15)),
    const DailyUsageData(dayLabel: 'Per', usageTime: Duration(hours: 6, minutes: 14), isSelected: true, isOverLimit: true),
    const DailyUsageData(dayLabel: 'Cum', usageTime: Duration(hours: 4, minutes: 45)),
    const DailyUsageData(dayLabel: 'Cmt', usageTime: Duration(hours: 7, minutes: 0)),
    const DailyUsageData(dayLabel: 'Paz', usageTime: Duration(hours: 3, minutes: 30)),
  ];

  static List<AppUsageData> get appLimits => [
    AppUsageData(
      appName: 'Instagram',
      iconType: 'instagram',
      usageTime: const Duration(hours: 2, minutes: 30),
      limitTime: const Duration(hours: 1, minutes: 30),
    ),
    AppUsageData(
      appName: 'YouTube',
      iconType: 'youtube',
      usageTime: const Duration(hours: 1, minutes: 45),
      limitTime: const Duration(hours: 2, minutes: 0),
    ),
    AppUsageData(
      appName: 'Twitter (X)',
      iconType: 'twitter',
      usageTime: const Duration(minutes: 55),
      limitTime: const Duration(hours: 1, minutes: 0),
    ),
  ];
}
