import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/onboarding_data.dart';

/// Third onboarding page - Awareness and Motivation
class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    final item = OnboardingData.items[2];
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Illustration with feature card overlay
            SizedBox(
              width: double.infinity,
              height: screenHeight * 0.35,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background blur circle
                  Positioned(
                    top: 10,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Feature card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.gray100,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Life Battery
                        _buildFeatureItem(
                          icon: Icons.battery_charging_full_rounded,
                          iconBgColor: AppColors.primary.withOpacity(0.1),
                          iconColor: AppColors.primary,
                          title: 'Yaşam Pili',
                          trailing: _buildProgressBar(0.75, AppColors.primary),
                        ),
                        const SizedBox(height: 16),
                        // Scroll Distance
                        _buildFeatureItem(
                          icon: Icons.straighten_rounded,
                          iconBgColor: AppColors.blue.withOpacity(0.1),
                          iconColor: AppColors.blue,
                          title: 'Kaydırma Mesafesi',
                          trailing: Text(
                            '124 metre',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Chain Calendar
                        _buildFeatureItem(
                          icon: Icons.calendar_month_rounded,
                          iconBgColor: AppColors.orange.withOpacity(0.1),
                          iconColor: AppColors.orange,
                          title: 'Zinciri Kırma',
                          trailing: _buildChainDots([true, true, true, false]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              'Alışkanlıklarını Keşfet,\nKendine Yatırım Yap',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayMedium.copyWith(
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.subtitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required Widget trailing,
  }) {
    return Row(
      children: [
        // Icon container
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        // Title and trailing
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              trailing,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress, Color color) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildChainDots(List<bool> completed) {
    return Row(
      children: completed.map((isComplete) {
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isComplete ? AppColors.primary : AppColors.gray200,
            shape: BoxShape.circle,
          ),
        );
      }).toList(),
    );
  }
}
