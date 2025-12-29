import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/data/home_data.dart';
import '../../../../core/services/usage_service.dart';

/// App usage limit card widget
class AppLimitCard extends StatelessWidget {
  final AppUsageData data;
  final VoidCallback? onTap;
  
  const AppLimitCard({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOverLimit = data.isOverLimit;
    final usagePercentage = data.usagePercentage.clamp(0.0, 1.0);
    final isWarning = usagePercentage > 0.8 && !isOverLimit;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gray200.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 1,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative corner for over limit
            if (isOverLimit)
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(48),
                    ),
                  ),
                ),
              ),
            Column(
              children: [
                // Header row
                Row(
                  children: [
                    // App icon
                    _buildAppIcon(),
                    const SizedBox(width: 16),
                    // App info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.appName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Limit: ${AppUsageData.formatDuration(data.limitTime)}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Usage stats
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppUsageData.formatDuration(data.usageTime),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildStatusIndicator(isOverLimit, isWarning),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress bar
                _buildProgressBar(usagePercentage, isOverLimit, isWarning),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIcon() {
    // App-specific gradients and colors
    Gradient? gradient;
    Color? solidColor;
    Widget iconWidget;
    
    switch (data.iconType) {
      case 'instagram':
        gradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFCAF45),
            Color(0xFFFF543E),
            Color(0xFFC837AB),
          ],
        );
        iconWidget = const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 24);
        break;
      case 'youtube':
        solidColor = const Color(0xFFFF0000);
        iconWidget = const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24);
        break;
      case 'twitter':
        solidColor = Colors.black;
        iconWidget = const Text('X', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800));
        break;
      default:
        // Eğer paket ismi ise icon çekelim
        if (data.iconType.contains('.')) {
          return FutureBuilder<String?>(
            future: UsageService.getAppIcon(data.iconType),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.memory(
                    base64Decode(snapshot.data!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                );
              }
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.apps_rounded, color: AppColors.textTertiary, size: 24),
              );
            },
          );
        }
        solidColor = AppColors.iosBlue;
        iconWidget = const Icon(Icons.apps_rounded, color: Colors.white, size: 24);
    }
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: gradient,
        color: solidColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(child: iconWidget),
    );
  }

  Widget _buildStatusIndicator(bool isOverLimit, bool isWarning) {
    if (isOverLimit) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${AppUsageData.formatDuration(data.debtTime)} Borç',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.warning_rounded, size: 14, color: AppColors.error),
        ],
      );
    } else if (isWarning) {
      return Text(
        '${AppUsageData.formatDuration(data.remainingTime)} kaldı',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      return Text(
        'Limit altı',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w600,
        ),
      );
    }
  }

  Widget _buildProgressBar(double percentage, bool isOverLimit, bool isWarning) {
    return AppLimitProgressBar(
      percentage: percentage,
      isOverLimit: isOverLimit,
    );
  }
}

/// Separate widget for progress bar with proper layout
class AppLimitProgressBar extends StatelessWidget {
  final double percentage;
  final bool isOverLimit;
  
  const AppLimitProgressBar({
    super.key,
    required this.percentage,
    this.isOverLimit = false,
  });

  @override
  Widget build(BuildContext context) {
    final safePercentage = percentage.clamp(0.0, 1.0);
    final overPercentage = (percentage - 1.0).clamp(0.0, 0.5);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        
        return Container(
          height: 10,
          width: maxWidth,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Stack(
            children: [
              // Base progress (green)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                width: isOverLimit 
                    ? maxWidth * (1.0 - overPercentage / (safePercentage + overPercentage))
                    : maxWidth * safePercentage,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.horizontal(
                    left: const Radius.circular(5),
                    right: isOverLimit ? Radius.zero : const Radius.circular(5),
                  ),
                ),
              ),
              // Over limit (red)
              if (isOverLimit)
                Positioned(
                  left: maxWidth * (1.0 - overPercentage / (safePercentage + overPercentage)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    width: maxWidth * (overPercentage / (safePercentage + overPercentage)),
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
