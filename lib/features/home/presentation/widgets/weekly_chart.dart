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
      padding: const EdgeInsets.all(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (index) => Expanded(
          child: GestureDetector(
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

  @override
  Widget build(BuildContext context) {
    final percentage = (data.usageTime.inMinutes / maxUsage.inMinutes).clamp(0.0, 1.0);
    const maxBarHeight = 140.0;
    final barHeight = maxBarHeight * percentage;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
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
