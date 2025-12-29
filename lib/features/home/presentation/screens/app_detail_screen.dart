import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../onboarding/presentation/widgets/onboarding_buttons.dart';
import '../../data/home_data.dart';
import '../../../../core/services/usage_service.dart';
import '../../../../core/services/limit_service.dart';

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
              // Spacer to balance the back button
              const SizedBox(width: 60),
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
    return Container(
      width: double.infinity,
      child: _StatCard(
        icon: Icons.schedule,
        iconColor: AppColors.iosBlue,
        iconBgColor: AppColors.iosBlue.withOpacity(0.1),
        label: 'BUGÜNKÜ KULLANIM',
        value: _usageDuration != null 
            ? AppUsageData.formatDuration(_usageDuration!) 
            : 'Yükleniyor...',
        subtitle: 'Toplam ekran süresi',
      ),
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
          _InfoRow(label: 'Kategori', value: widget.category),
          const Divider(height: 24),
          _InfoRow(label: 'Paket Adı', value: widget.appName, valueColor: AppColors.textTertiary),
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
          _showAddLimitDialog();
        },
        showArrow: false,
      ),
    );
  }

  void _showAddLimitDialog() {
    int hours = 1;
    int minutes = 0;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Süre Limiti Belirle', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$_displayTitle için günlük kullanım limiti seçin.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPickerColumn('Saat', 0, 23, hours, (val) => setModalState(() => hours = val)),
                  const Text(':', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  _buildPickerColumn('Dakika', 0, 59, minutes, (val) => setModalState(() => minutes = val)),
                ],
              ),
              const SizedBox(height: 32),
              BlueButton(
                text: 'Limiti Kaydet',
                onPressed: () async {
                  final limitMinutes = (hours * 60) + minutes;
                  if (limitMinutes == 0) return;

                  await LimitService.saveLimit(AppLimit(
                    packageName: widget.appName,
                    appName: _displayTitle,
                    limitMinutes: limitMinutes,
                  ));
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$_displayTitle için ${hours}sa ${minutes}dk limit eklendi'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                showArrow: false,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerColumn(String label, int min, int max, int current, Function(int) onSelected) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.overline.copyWith(color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          width: 80,
          child: ListWheelScrollView.useDelegate(
            itemExtent: 50,
            onSelectedItemChanged: onSelected,
            physics: const FixedExtentScrollPhysics(),
            controller: FixedExtentScrollController(initialItem: current),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: max - min + 1,
              builder: (context, index) {
                final val = index + min;
                final isSelected = val == current;
                return Center(
                  child: Text(
                    val.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: isSelected ? 32 : 24,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? AppColors.textPrimary : AppColors.gray300,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Duration label on top
            Text(
              _formatDuration(duration),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isHighlighted ? AppColors.iosBlue : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
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
