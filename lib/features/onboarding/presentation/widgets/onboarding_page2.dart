import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/onboarding_data.dart';

/// Second onboarding page - Screen Time Control
class OnboardingPage2 extends StatelessWidget {
  const OnboardingPage2({super.key});

  @override
  Widget build(BuildContext context) {
    final item = OnboardingData.items[1];
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Illustration area
            Container(
              width: double.infinity,
              height: screenHeight * 0.35,
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppColors.gray50,
              ),
              child: Stack(
                children: [
                  // Background gradient
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.08),
                          AppColors.primary.withOpacity(0.02),
                        ],
                      ),
                    ),
                  ),
                  // Decorative elements
                  Positioned(
                    top: 30,
                    left: 20,
                    child: _buildAppIcon(
                      Icons.phone_android_rounded,
                      AppColors.primary.withOpacity(0.15),
                      AppColors.primary,
                    ),
                  ),
                  Positioned(
                    top: 50,
                    right: 30,
                    child: _buildAppIcon(
                      Icons.schedule_rounded,
                      AppColors.iosBlue.withOpacity(0.15),
                      AppColors.iosBlue,
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 40,
                    child: _buildAppIcon(
                      Icons.apps_rounded,
                      AppColors.orange.withOpacity(0.15),
                      AppColors.orange,
                    ),
                  ),
                  Positioned(
                    bottom: 50,
                    right: 25,
                    child: _buildAppIcon(
                      Icons.timer_rounded,
                      AppColors.purple.withOpacity(0.15),
                      AppColors.purple,
                    ),
                  ),
                  // Center phone mockup with timer
                  Center(
                    child: Container(
                      width: 120,
                      height: 170,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Lock/Timer icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_clock_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Time limit text
                          Text(
                            '2:00:00',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kalan Süre',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Simulated progress bar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.gray200,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: 0.6,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Title with line break
            Text(
              'Zamanını Yönet,\nHayatını Yaşa',
              textAlign: TextAlign.center,
              style: AppTextStyles.displayMedium.copyWith(
                height: 1.15,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
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

  Widget _buildAppIcon(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
    );
  }
}
