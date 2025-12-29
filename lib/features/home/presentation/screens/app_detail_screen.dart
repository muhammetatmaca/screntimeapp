import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../onboarding/presentation/widgets/onboarding_buttons.dart';
import '../../data/home_data.dart';
import '../../../../core/services/usage_service.dart';

/// App detail screen showing usage statistics for a specific app
class AppDetailScreen extends StatefulWidget {
  final String appName;
  final String category;
  final String iconType;
  
  const AppDetailScreen({
    super.key,
    required this.appName,
    this.category = 'Sosyal Ağlar',
    this.iconType = 'instagram',
  });

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  // İçerik Odaklanma toggleları
  bool _reelsBlocked = true;
  bool _storiesBlocked = false;
  String _displayTitle = "";
  String _effectiveIconType = "default";
  Duration? _usageDuration;
  List<Duration> _weeklyUsage = List.filled(7, Duration.zero);
  bool _isLoadingChart = true;

  @override
  void initState() {
    super.initState();
    _displayTitle = widget.appName;
    _effectiveIconType = widget.iconType;
    _resolveDisplayName();
    _loadAppUsage();
  }

  void _resolveDisplayName() {
    if (widget.appName.contains('.')) {
      final Map<String, String> commonApps = {
        'com.instagram.android': 'Instagram',
        'com.google.android.youtube': 'YouTube',
        'com.twitter.android': 'Twitter (X)',
        'com.whatsapp': 'WhatsApp',
        'com.facebook.katana': 'Facebook',
        'com.android.chrome': 'Chrome',
        'com.google.android.googlequicksearchbox': 'Google',
      };

      if (commonApps.containsKey(widget.appName)) {
        _displayTitle = commonApps[widget.appName]!;
        _effectiveIconType = widget.appName.split('.').contains('instagram') ? 'instagram' : 
                            widget.appName.split('.').contains('youtube') ? 'youtube' : 
                            widget.appName.split('.').contains('twitter') ? 'twitter' : _effectiveIconType;
      } else {
        List<String> parts = widget.appName.split('.');
        String candidate = parts.length > 2 ? parts[parts.length - 2] : parts.last;
        if ((candidate == 'android' || candidate == 'apps') && parts.length > 2) {
          candidate = parts[parts.length - 1];
        }
        _displayTitle = candidate[0].toUpperCase() + candidate.substring(1);
      }
    }
  }

  Future<void> _loadAppUsage() async {
    final usage = await UsageService.getUsageForApp(widget.appName);
    
    // Son 7 günün verilerini yükle
    final List<Duration> weeklyData = [];
    for (int i = 6; i >= 0; i--) {
      final dayApps = await UsageService.getAppListForDay(i);
      final appUsage = dayApps.firstWhere(
        (app) => app.packageName == widget.appName,
        orElse: () => AppUsageRecord(
          packageName: widget.appName,
          usage: Duration.zero,
        ),
      );
      weeklyData.add(appUsage.usage);
    }
    
    if (mounted) {
      setState(() {
        _usageDuration = usage;
        _weeklyUsage = weeklyData;
        _isLoadingChart = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // Header
          _buildHeader(context),
          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App icon and name
                  _buildAppHeader(),
                  const SizedBox(height: 24),
                  // Stats cards
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  // Daily usage chart
                  _buildUsageChart(),
                  const SizedBox(height: 24),
                  // Content Focus section
                  _buildContentFocusSection(),
                  const SizedBox(height: 24),
                  // History section
                  _buildHistorySection(),
                  const SizedBox(height: 24),
                  // Additional info
                  _buildAdditionalInfo(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom button
      bottomSheet: _buildBottomButton(),
    );
  }

  Widget _buildContentFocusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'İÇERİK ODAKLANMA',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.gray100,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Instagram Reels
              _ContentFocusItem(
                icon: Icons.movie_rounded,
                iconColor: const Color(0xFFDB2777),
                iconBgColor: const Color(0xFFFCE7F3),
                title: '${widget.appName} Reels',
                subtitle: '45 dk',
                statusText: 'Engelleme: ${_reelsBlocked ? "AÇIK" : "KAPALI"}',
                statusColor: _reelsBlocked ? AppColors.error : AppColors.textSecondary,
                value: _reelsBlocked,
                onChanged: (v) => setState(() => _reelsBlocked = v),
              ),
              Divider(height: 1, color: AppColors.gray100),
              // Stories
              _ContentFocusItem(
                icon: Icons.amp_stories_rounded,
                iconColor: const Color(0xFFEA580C),
                iconBgColor: const Color(0xFFFFF7ED),
                title: 'Hikayeler',
                subtitle: '12 dk harcandı',
                value: _storiesBlocked,
                onChanged: (v) => setState(() => _storiesBlocked = v),
                isLast: true,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
          child: Text(
            'Kısa süreli video içerikleri için özel zaman sınırları belirleyebilir veya tamamen erişimi kısıtlayabilirsiniz.',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.05),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chevron_left,
                        color: AppColors.iosBlue,
                        size: 26,
                      ),
                      Text(
                        'Geri',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.iosBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Title
              Expanded(
                child: Text(
                  _displayTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Edit button
              GestureDetector(
                onTap: () {
                  // Edit
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Düzenle',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.iosBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Center(
      child: Column(
        children: [
          // App icon
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white,
              boxShadow: AppColors.cardShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _buildAppIcon(_effectiveIconType, 84),
            ),
          ),
          const SizedBox(height: 12),
          // App name
          Text(
            _displayTitle,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          // Category
          Text(
            widget.category,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon(String type, double size) {
    Gradient? gradient;
    Color? solidColor;
    Widget iconWidget;
    
    switch (type) {
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
        iconWidget = Icon(Icons.camera_alt_rounded, color: Colors.white, size: size * 0.4);
        break;
      case 'youtube':
        solidColor = const Color(0xFFFF0000);
        iconWidget = Icon(Icons.play_arrow_rounded, color: Colors.white, size: size * 0.5);
        break;
      case 'twitter':
        solidColor = Colors.black;
        iconWidget = Text('X', style: TextStyle(color: Colors.white, fontSize: size * 0.3, fontWeight: FontWeight.w800));
        break;
      default:
        solidColor = AppColors.iosBlue;
        iconWidget = Icon(Icons.apps_rounded, color: Colors.white, size: size * 0.4);
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        color: solidColor,
      ),
      child: Center(child: iconWidget),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.schedule,
            iconColor: AppColors.iosBlue,
            iconBgColor: AppColors.iosBlue.withOpacity(0.1),
            label: 'SÜRE',
            value: _usageDuration != null 
                ? AppUsageData.formatDuration(_usageDuration!) 
                : 'Yükleniyor...',
            subtitle: 'Bugünkü Kullanım',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.touch_app_rounded,
            iconColor: const Color(0xFF8B5CF6),
            iconBgColor: const Color(0xFF8B5CF6).withOpacity(0.1),
            label: 'OTURUM',
            value: '12 kez',
            subtitle: 'Bugünkü Açılış',
          ),
        ),
      ],
    );
  }

  Widget _buildUsageChart() {
    final dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    final now = DateTime.now();
    final today = now.weekday - 1; // 0 = Pazartesi, 6 = Pazar
    
    // En yüksek kullanımı bul (normalize etmek için)
    final maxUsage = _weeklyUsage.isEmpty 
        ? Duration.zero 
        : _weeklyUsage.reduce((a, b) => a > b ? a : b);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Günlük Kullanım',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Son 7 Gün',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Chart
          Padding(
            padding: const EdgeInsets.all(20),
            child: _isLoadingChart
                ? const SizedBox(
                    height: 140,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.iosBlue),
                    ),
                  )
                : SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final usage = _weeklyUsage[index];
                        final percentage = maxUsage.inMinutes > 0
                            ? (usage.inMinutes / maxUsage.inMinutes)
                            : 0.0;
                        
                        return _ChartBar(
                          label: dayLabels[index],
                          percentage: percentage,
                          duration: usage,
                          isHighlighted: index == today,
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'DETAYLI GEÇMİŞ',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _HistoryItem(day: 'Dün', date: '21 Ekim', duration: '1s 12dk'),
              const Divider(height: 1, indent: 20),
              _HistoryItem(day: 'Salı', date: '20 Ekim', duration: '45dk'),
              const Divider(height: 1, indent: 20),
              _HistoryItem(day: 'Pazartesi', date: '19 Ekim', duration: '2s 05dk', showBorder: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Oturum Sayısı', value: '12 kez/gün'),
          const Divider(height: 24),
          _InfoRow(label: 'Kategori Limiti', value: 'Belirlenmedi', valueColor: AppColors.iosBlue),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      color: Colors.white.withOpacity(0.9),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: BlueButton(
        text: 'Süre Limiti Ekle',
        onPressed: () {
          // Add time limit
        },
        showArrow: false,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final String label;
  final double percentage;
  final Duration duration;
  final bool isHighlighted;

  const _ChartBar({
    required this.label,
    required this.percentage,
    required this.duration,
    this.isHighlighted = false,
  });

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}s ${d.inMinutes % 60}dk';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}dk';
    } else {
      return '0dk';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: _formatDuration(duration),
        preferBelow: false,
        verticalOffset: 20,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        child: GestureDetector(
          onLongPress: () {
            // Tooltip otomatik gösterilir
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Background
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      // Fill
                      FractionallySizedBox(
                        heightFactor: percentage,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.iosBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isHighlighted ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String day;
  final String date;
  final String duration;
  final bool showBorder;

  const _HistoryItem({
    required this.day,
    required this.date,
    required this.duration,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                duration,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: AppColors.gray300,
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium,
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Content Focus Item widget with toggle switch
class _ContentFocusItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String? statusText;
  final Color? statusColor;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _ContentFocusItem({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.statusText,
    this.statusColor,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (statusText != null) ...[
                      Text(
                        ' • ',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        statusText!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: statusColor ?? AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Toggle
          _IOSToggle(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// iOS style toggle switch
class _IOSToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _IOSToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 30,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? AppColors.success : AppColors.gray200,
          borderRadius: BorderRadius.circular(15),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

