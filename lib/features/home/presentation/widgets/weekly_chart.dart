import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/data/home_data.dart';

/// Weekly usage bar chart widget
class WeeklyChart extends StatelessWidget {
  final List<DailyUsageData> data;
  final Duration maxUsage;
  final Function(int)? onDaySelected;
  
  const WeeklyChart({
    super.key,
    required this.data,
    this.onDaySelected,
    Duration? maxUsage,
  }) : maxUsage = maxUsage ?? const Duration(hours: 8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (index) => Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onDaySelected?.call(index),
            child: _DayBar(
              data: data[index],
              maxUsage: maxUsage,
            ),
          ),
        )),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final DailyUsageData data;
  final Duration maxUsage;
  
  const _DayBar({
    required this.data,
    required this.maxUsage,
  });

  String _formatUsage(Duration duration) {
    if (duration == Duration.zero) return "0s";
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    if (hours > 0) return "${hours}s";
    return "${mins}dk";
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (data.usageTime.inMinutes / maxUsage.inMinutes).clamp(0.0, 1.0);
    const maxBarHeight = 120.0;
    final barHeight = maxBarHeight * percentage;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Usage Time on Top
          Text(
            _formatUsage(data.usageTime),
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: 9,
              color: data.isSelected ? AppColors.textPrimary : AppColors.textTertiary,
              fontWeight: data.isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          // Bar container
          SizedBox(
            height: maxBarHeight,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Background bar
                Container(
                  width: double.infinity,
                  height: maxBarHeight,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Filled bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: data.isSelected 
                        ? AppColors.textPrimary 
                        : AppColors.gray300,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: data.isSelected ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: data.isOverLimit 
                      ? Stack(
                          children: [
                            // Over limit indicator (red top)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: barHeight * 0.15,
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Day label
          Text(
            data.dayLabel,
            style: AppTextStyles.labelSmall.copyWith(
              color: data.isSelected 
                  ? AppColors.textPrimary 
                  : AppColors.textTertiary,
              fontWeight: data.isSelected 
                  ? FontWeight.w800 
                  : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
