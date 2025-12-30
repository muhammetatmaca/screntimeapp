import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class WidgetSettingsScreen extends StatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  int _usageSizeIndex = 1; // 0: Küçük, 1: Orta
  int _batterySizeIndex = 0; // 0: Küçük
  int _topAppsSizeIndex = 1; // 1: Orta
  int _detoxSizeIndex = 0; // 0: Küçük, 1: Orta
  int _calendarSizeIndex = 1; // 1: Orta
  int _pomodoroSizeIndex = 0; // 0: Küçük
  int _billSizeIndex = 2; // 2: Büyük (Fatura için)
  int _scrollSizeIndex = 1; // 1: Orta
  
  bool _showTimeGoal = true;
  bool _showAppNameShortcuts = true;
  bool _isDarkModeTheme = false;
  bool _showPercentageInBattery = true;
  bool _showWeekNumbers = false;
  bool _showSessionCount = true;
  bool _showScrollComparison = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.iosBlue, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Widgetlar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                      children: [
                        const TextSpan(text: 'Ana Ekranınızı\n'),
                        TextSpan(
                          text: 'Kişiselleştirin',
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kullanım alışkanlıklarınızı anlık olarak takip etmek için widget\'ları ana ekranınıza ekleyin.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Usage Summary Section
            _buildSectionHeader('Kullanım Özeti', showBadge: true),
            _buildWidgetPreviewArea(
              child: _buildUsageSummaryWidget(),
              isDark: false,
            ),
            _buildControls(
              sizeIndex: _usageSizeIndex,
              onSizeChanged: (i) => setState(() => _usageSizeIndex = i),
              count: 2,
              toggles: [
                _ControlToggle(
                  label: 'Kullanım Hedefini Göster',
                  value: _showTimeGoal,
                  onChanged: (v) => setState(() => _showTimeGoal = v),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 64),
            ),

            // Life Battery Section
            _buildSectionHeader('Yaşam Pili'),
            _buildWidgetPreviewArea(
              child: _buildBatteryWidget(),
              isDark: false,
            ),
            _buildControls(
              sizeIndex: _batterySizeIndex,
              onSizeChanged: (i) => setState(() => _batterySizeIndex = i),
              count: 1,
              toggles: [
                _ControlToggle(
                  label: 'Yüzde Göster',
                  value: _showPercentageInBattery,
                  onChanged: (v) => setState(() => _showPercentageInBattery = v),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 64),
            ),

            // Top Apps Section
            _buildSectionHeader('En Çok Kullanılanlar'),
            _buildWidgetPreviewArea(
              child: _buildTopAppsWidget(),
              isDark: false,
            ),
            _buildControls(
              sizeIndex: _topAppsSizeIndex,
              onSizeChanged: (i) => setState(() => _topAppsSizeIndex = i),
              count: 2,
              toggles: [
                _ControlToggle(
                  label: 'Uygulama İsimlerini Göster',
                  value: _showAppNameShortcuts,
                  onChanged: (v) => setState(() => _showAppNameShortcuts = v),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 64),
            ),

            // Detox Status Section
            _buildSectionHeader('Detoks & Borç'),
            _buildWidgetPreviewArea(
              child: _buildDetoxStatusWidget(),
              isDark: false,
            ),
            _buildControls(
              sizeIndex: _detoxSizeIndex,
              onSizeChanged: (i) => setState(() => _detoxSizeIndex = i),
              count: 2,
              toggles: [
                _ControlToggle(
                  label: 'Karanlık Mod Teması',
                  value: _isDarkModeTheme,
                  onChanged: (v) => setState(() => _isDarkModeTheme = v),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 64),
            ),

            // Calendar Section
            _buildSectionHeader('Takvim Görünümü'),
            _buildWidgetPreviewArea(
              child: _buildCalendarWidget(),
              isDark: false,
            ),
            _buildControls(
              sizeIndex: _calendarSizeIndex,
              onSizeChanged: (i) => setState(() => _calendarSizeIndex = i),
              count: 2,
              toggles: [
                _ControlToggle(
                  label: 'Hafta Numaralarını Göster',
                  value: _showWeekNumbers,
                  onChanged: (v) => setState(() => _showWeekNumbers = v),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 64),
            ),

            // Pomodoro Section
            _buildSectionHeader('Pomodoro Saati'),
            _buildWidgetPreviewArea(
              child: _buildPomodoroWidget(),
              isDark: false,
            ),
            _buildControls(
              sizeIndex: _pomodoroSizeIndex,
              onSizeChanged: (i) => setState(() => _pomodoroSizeIndex = i),
              count: 2,
              toggles: [
                _ControlToggle(
                  label: 'Tamamlanan Seansları Göster',
                  value: _showSessionCount,
                  onChanged: (v) => setState(() => _showSessionCount = v),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 64),
            ),

            // Detailed Bill Section
            _buildSectionHeader('Dijital Fatura (Top 5)'),
            _buildWidgetPreviewArea(
              child: _buildDetailedBillWidget(),
              isDark: false,
            ),
            _buildControls(
              sizeIndex: _billSizeIndex,
              onSizeChanged: (i) => setState(() => _billSizeIndex = i),
              count: 3,
              toggles: [],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 64),
            ),

            // Scroll Distance Section
            _buildSectionHeader('Kaydırma Mesafesi'),
            _buildWidgetPreviewArea(
              child: _buildScrollWidget(),
              isDark: false,
            ),
            _buildControls(
              sizeIndex: _scrollSizeIndex,
              onSizeChanged: (i) => setState(() => _scrollSizeIndex = i),
              count: 2,
              toggles: [
                _ControlToggle(
                  label: 'Karşılaştırmayı Göster',
                  value: _showScrollComparison,
                  onChanged: (v) => setState(() => _showScrollComparison = v),
                ),
              ],
            ),

            // Guide Section
            _buildGuideSection(),

            const SizedBox(height: 32),
            // Bottom Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Tamamla',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {bool showBadge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
          ),
          if (showBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(fullRadius),
              ),
              child: Text(
                'Popüler',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const double fullRadius = 9999;

  Widget _buildWidgetPreviewArea({required Widget child, bool isDark = false}) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF6F8F6),
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: CustomPaint(
                painter: _DotPatternPainter(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildUsageSummaryWidget() {
    final width = _usageSizeIndex == 0 ? 150.0 : 320.0;
    const height = 150.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: AppColors.iosBlue, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'BUGÜN',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '3s 12dk',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1),
                  ),
                ],
              ),
              if (_usageSizeIndex != 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Düne Göre',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                    const Text(
                      '-%12',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.success),
                    ),
                  ],
                ),
            ],
          ),
          if (_showTimeGoal)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Günlük Limit',
                      style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      '%45',
                      style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.45,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.iosBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBatteryWidget() {
    const width = 150.0;
    const height = 150.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.battery_charging_full_rounded, color: AppColors.success, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Yaşam Pili',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                _showPercentageInBattery ? '%84' : 'Dolu',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppsWidget() {
    const width = 320.0;
    const height = 150.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EN ÇOK KULLANILANLAR',
            style: AppTextStyles.overline.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAppStat('Instagram', '1s 20dk', Colors.purple, 1.0),
                _buildAppStat('YouTube', '45dk', Colors.red, 0.6),
                _buildAppStat('Twitter', '32dk', Colors.blue, 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppStat(String name, String time, Color color, double progress) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                color: color,
                backgroundColor: color.withOpacity(0.1),
                strokeCap: StrokeCap.round,
              ),
            ),
            Icon(Icons.apps_rounded, color: color, size: 20),
          ],
        ),
        if (_showAppNameShortcuts) ...[
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          Text(time, style: TextStyle(fontSize: 9, color: AppColors.textTertiary)),
        ],
      ],
    );
  }

  Widget _buildDetoxStatusWidget() {
    final width = 150.0;
    final height = 150.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _isDarkModeTheme ? const Color(0xFF111813) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
        border: _isDarkModeTheme ? null : Border.all(color: AppColors.gray100),
      ),
      child: Stack(
        children: [
          if (_isDarkModeTheme)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: 0.7,
                        strokeWidth: 6,
                        color: AppColors.primary,
                        backgroundColor: _isDarkModeTheme ? Colors.white.withOpacity(0.1) : AppColors.gray100,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Icon(
                      Icons.spa_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '45dk',
                  style: TextStyle(
                    color: _isDarkModeTheme ? Colors.white : AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Odaklanıldı',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarWidget() {
    final isSmall = _calendarSizeIndex == 0;
    final width = isSmall ? 150.0 : 320.0;
    const height = 150.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aralık 2023',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: isSmall ? 10 : 13,
                ),
              ),
              if (_showWeekNumbers && !isSmall)
                const Text('H.52', style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(isSmall ? 5 : 7, (index) {
                final days = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
                final isToday = index == (isSmall ? 2 : 4);
                return Column(
                  children: [
                    Text(days[index], style: TextStyle(fontSize: isSmall ? 8 : 10, color: AppColors.textTertiary)),
                    const SizedBox(height: 8),
                    Container(
                      width: isSmall ? 18 : 24,
                      height: isSmall ? 18 : 24,
                      decoration: BoxDecoration(
                        color: isToday ? AppColors.iosBlue : ((isSmall ? index < 2 : index < 4) ? AppColors.success.withOpacity(0.2) : Colors.transparent),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${20 + index}',
                          style: TextStyle(
                            fontSize: isSmall ? 8 : 10,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroWidget() {
    final width = _pomodoroSizeIndex == 0 ? 150.0 : 320.0;
    const height = 150.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFF5252),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF5252).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.timer_rounded, color: Colors.white, size: 24),
              if (_showSessionCount)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Seans: 3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ODAKLAN', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              SizedBox(height: 2),
              Text('24:12', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300, fontFamily: 'monospace')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBillWidget() {
    final width = _billSizeIndex == 0 ? 150.0 : (_billSizeIndex == 1 ? 320.0 : 320.0);
    final height = _billSizeIndex == 2 ? 280.0 : 150.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DİJİTAL FATURA', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const Text('3s 45dk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                ],
              ),
              const Icon(Icons.qr_code_2_rounded, size: 40, color: AppColors.textPrimary),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          const Text('İLK 5 UYGULAMA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBillItem('Instagram', '1s 12dk', Colors.purple),
                _buildBillItem('YouTube', '45dk', Colors.red),
                _buildBillItem('Twitter', '32dk', Colors.blue),
                _buildBillItem('WhatsApp', '28dk', Colors.green),
                _buildBillItem('TikTok', '22dk', Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillItem(String name, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(time, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildScrollWidget() {
    final isSmall = _scrollSizeIndex == 0;
    final width = isSmall ? 150.0 : 320.0;
    const height = 150.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 24),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.swap_vert_rounded, color: Colors.amber, size: 20),
              ),
              if (!isSmall)
                Text(
                  'KAYDIRMA',
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('1.2 km', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -1)),
              if (_showScrollComparison && !isSmall) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('🗼', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '3.5 Eyfel Kulesi',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls({
    required int sizeIndex,
    required ValueChanged<int> onSizeChanged,
    int count = 3,
    required List<_ControlToggle> toggles,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          // Size Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildSizeButton('Küçük', 0, sizeIndex == 0, onSizeChanged),
                _buildSizeButton('Orta', 1, sizeIndex == 1, onSizeChanged),
                if (count == 3) _buildSizeButton('Büyük', 2, sizeIndex == 2, onSizeChanged),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Toggles
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: toggles.length,
            separatorBuilder: (_, __) => Divider(color: AppColors.gray100.withOpacity(0.5), height: 1),
            itemBuilder: (context, index) {
              final toggle = toggles[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      toggle.label,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Switch.adaptive(
                      value: toggle.value,
                      onChanged: toggle.onChanged,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSizeButton(String label, int index, bool isSelected, ValueChanged<int> onSizeChanged) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onSizeChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
            border: isSelected ? Border.all(color: AppColors.gray200, width: 0.5) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8F6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.add_to_home_screen_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Widget Nasıl Eklenir?',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildGuideStep('1.', 'Ana ekranda boş bir yere basılı tutun.'),
                  _buildGuideStep('2.', 'Sol üst köşedeki (+) butonuna dokunun.'),
                  _buildGuideStep('3.', 'Listeden "Ekran Faturası"nı seçin.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 12)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlToggle {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  _ControlToggle({required this.label, required this.value, required this.onChanged});
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
