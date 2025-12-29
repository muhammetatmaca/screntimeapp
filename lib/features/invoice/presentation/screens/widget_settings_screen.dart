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
  int _summarySizeIndex = 1; // 0: Küçük, 1: Orta, 2: Büyük
  int _detoxSizeIndex = 0; // 0: Küçük, 1: Orta
  bool _showSpendingLimit = true;
  bool _showCurrencySymbol = true;
  bool _isDarkModeTheme = true;

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
                    'Harcamalarınızı ve ekran sürenizi takip etmek için widget\'ları ana ekranınıza ekleyin.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Bill Summary Section
            _buildSectionHeader('Fatura Özeti', showBadge: true),
            _buildWidgetPreviewArea(
              child: _buildBillSummaryWidget(),
              isDark: false,
            ),
            _buildControls(
              sizeIndex: _summarySizeIndex,
              onSizeChanged: (i) => setState(() => _summarySizeIndex = i),
              toggles: [
                _ControlToggle(
                  label: 'Harcama Limitini Göster',
                  value: _showSpendingLimit,
                  onChanged: (v) => setState(() => _showSpendingLimit = v),
                ),
                _ControlToggle(
                  label: 'Döviz Simgesi',
                  value: _showCurrencySymbol,
                  onChanged: (v) => setState(() => _showCurrencySymbol = v),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(height: 64),
            ),

            // Detox Status Section
            _buildSectionHeader('Detoks Durumu'),
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

  Widget _buildBillSummaryWidget() {
    final width = _summarySizeIndex == 0 ? 150.0 : 320.0;
    final height = 150.0;

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
                      const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 18),
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
                  Row(
                    children: [
                      if (_showCurrencySymbol)
                        const Text(
                          '₺',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      const Text(
                        '24,50',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
              if (_summarySizeIndex != 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Süre',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                    const Text(
                      '3s 12dk',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
            ],
          ),
          if (_showSpendingLimit)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Harcama Limiti',
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
                        color: AppColors.primary,
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
