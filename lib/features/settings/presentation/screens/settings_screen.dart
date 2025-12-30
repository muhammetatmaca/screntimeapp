import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../invoice/presentation/screens/widget_settings_screen.dart';
import '../../../../core/services/settings_service.dart';
import '../../../onboarding/presentation/widgets/onboarding_buttons.dart';

/// Settings screen with glass morphism design
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedTab = 3; // 3: Routine (Default now as requested)
  
  double _sleepHours = 8.0;
  double _workHours = 8.0;
  double _dailyGoal = 4.0;
  bool _isLoading = true;
  
  // Toggle states
  bool _mentionsEnabled = true;
  bool _newEventInvitesEnabled = true;
  bool _remindersEnabled = true;
  bool _announcementsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final sleep = await SettingsService.getSleepHours();
    final work = await SettingsService.getWorkHours();
    final goal = await SettingsService.getDailyGoalHours();
    if (mounted) {
      setState(() {
        _sleepHours = sleep;
        _workHours = work;
        _dailyGoal = goal;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Klavye açıldığında resmin bozulmaması için
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg1.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
          ),
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Glass card
                  _buildGlassCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard() {
    return Container(
      width: double.infinity,
      decoration: ShapeDecoration(
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 1,
            color: Colors.white.withOpacity(0.15),
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        shadows: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tabs
              _buildHeader(),
              // Content
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 28, left: 24, right: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Ayarlar',
            style: AppTextStyles.headlineLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          // Tabs
          Row(
            children: [
              _buildTab('Gizlilik', 0),
              _buildTab('Bildirimler', 1),
              _buildTab('Uygulama', 2),
              _buildTab('Rutin', 3),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              width: 2,
              color: isSelected ? Colors.white : Colors.transparent,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildPrivacyContent();
      case 1:
        return _buildNotificationContent();
      case 2:
        return _buildAppContent();
      case 3:
        return _buildRoutineContent();
      default:
        return _buildRoutineContent();
    }
  }

  Widget _buildPrivacyContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gizlilik ve Veri',
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Verileriniz sadece cihazınızda saklanır ve asla sunucularımıza gönderilmez.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          _buildMenuItem(
            title: 'Gizlilik Politikası',
            description: 'Uygulamanın gizlilik prensiplerini inceleyin.',
            icon: Icons.privacy_tip_outlined,
            onTap: () {},
          ),
          _buildMenuItem(
            title: 'Kullanım Koşulları',
            description: 'Kullanım şartları ve yasal bilgiler.',
            icon: Icons.description_outlined,
            onTap: () {},
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggleItem(
            title: 'Limit Uyarıları',
            description: 'Uygulama limitine 5 dakika kala bildirim gönder.',
            value: _remindersEnabled,
            onChanged: (v) => setState(() => _remindersEnabled = v),
          ),
          _buildToggleItem(
            title: 'Limit Doldu Bildirimi',
            description: 'Uygulama süresi bittiğinde anında uyar.',
            value: _mentionsEnabled,
            onChanged: (v) => setState(() => _mentionsEnabled = v),
          ),
          _buildToggleItem(
            title: 'Haftalık Rapor',
            description: 'Her Pazar günü haftalık analiz bildirimi al.',
            value: _newEventInvitesEnabled,
            onChanged: (v) => setState(() => _newEventInvitesEnabled = v),
          ),
          _buildMenuItem(
            title: 'Sistem Ayarları',
            description: 'Cihaz bildirim ayarlarına git.',
            icon: Icons.settings_applications_rounded,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAppContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuItem(
            title: 'Karanlık Mod',
            description: 'Uygulama temasını değiştir (Yakında).',
            icon: Icons.dark_mode_rounded,
            onTap: () {},
          ),
          _buildMenuItem(
            title: 'Widget Ayarları',
            description: 'Ana ekran araçlarını özelleştirin.',
            icon: Icons.widgets_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const WidgetSettingsScreen()),
              );
            },
          ),
          _buildMenuItem(
            title: 'Hakkında',
            description: 'Versiyon 1.0.0+1',
            icon: Icons.info_outline_rounded,
            onTap: () {},
          ),
          _buildMenuItem(
            title: 'Geri Bildirim',
            description: 'Uygulama hakkında fikirlerinizi paylaşın.',
            icon: Icons.feedback_outlined,
            onTap: () {},
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Günlük Rutin',
            style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Yaşam pilini hesaplamak için uyku ve iş sürelerini girin.',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(height: 32),
          _buildSliderItem(
            title: 'Ortalama Uyku',
            value: _sleepHours,
            min: 4,
            max: 12,
            icon: Icons.bedtime_rounded,
            onChanged: (val) => setState(() => _sleepHours = val),
          ),
          const SizedBox(height: 24),
          _buildSliderItem(
            title: 'Günlük İş / Okul',
            value: _workHours,
            min: 0,
            max: 14,
            icon: Icons.work_rounded,
            onChanged: (val) => setState(() => _workHours = val),
          ),
          const SizedBox(height: 24),
          _buildSliderItem(
            title: 'Günlük Hedef (Odak)',
            value: _dailyGoal,
            min: 1,
            max: 12,
            icon: Icons.track_changes_rounded,
            onChanged: (val) => setState(() => _dailyGoal = val),
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            text: 'Rutini Kaydet',
            onPressed: () async {
              await SettingsService.saveRoutineSettings(
                _sleepHours, 
                _workHours,
                goal: _dailyGoal,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rutin başarıyla kaydedildi!')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderItem({
    required String title,
    required double value,
    required double min,
    required double max,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(title, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
            Text('${value.toStringAsFixed(1)} saat', style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.3), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isLast = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Toggle switch
          _GlassToggle(
            value: value,
            onChanged: onChanged,
          ),
          const SizedBox(width: 20),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.68),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom glass toggle switch
class _GlassToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _GlassToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value 
              ? Colors.white.withOpacity(0.40)
              : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(100),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1E000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
