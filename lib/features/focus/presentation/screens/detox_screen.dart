import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/focus_service.dart';

/// Detox Mode Screen - Borç Ödeme
class DetoxScreen extends StatefulWidget {
  const DetoxScreen({super.key});

  @override
  State<DetoxScreen> createState() => _DetoxScreenState();
}

class _DetoxScreenState extends State<DetoxScreen> {
  bool _isActive = false;
  Timer? _timer;
  int _elapsedSeconds = 0;
  double _earnedMinutes = 0;
  DetoxDebt? _currentDebt;

  @override
  void initState() {
    super.initState();
    _loadDebt();
  }

  Future<void> _loadDebt() async {
    final debt = await FocusService.getDebt();
    if (mounted) {
      setState(() => _currentDebt = debt);
    }
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startDetox() {
    setState(() {
      _isActive = true;
      _elapsedSeconds = 0;
      _earnedMinutes = 0;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        // 2 saniye detoks = 1 saniye borç silme (2:1 oranı)
        // Burada saniyeyi dakikaya çevirip FocusService'e uygun hale getiriyoruz
        _earnedMinutes = _elapsedSeconds / 120; // 120sn detoks = 1dk borç silme
      });
    });
  }

  Future<void> _stopDetox() async {
    _timer?.cancel();
    if (_elapsedSeconds > 0) {
      // Borcu kalıcı olarak düşür
      await FocusService.reduceDebt(_elapsedSeconds / 60);
      await _loadDebt();
    }
    setState(() {
      _isActive = false;
    });
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDebt(double minutes) {
    int totalMinutes = minutes.round();
    int hours = totalMinutes ~/ 60;
    int mins = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}sa ${mins}dk';
    }
    return '${mins}dk';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isActive ? const Color(0xFF111813) : Colors.white,
      body: _isActive ? _buildActiveView() : _buildReadyView(),
    );
  }

  Widget _buildReadyView() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Borç Ödeme',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'GÜNCEL FATURA',
                          style: AppTextStyles.overline.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Debt display
                  Builder(
                    builder: (context) {
                      final totalMinutes = _currentDebt?.totalMinutes.round() ?? 0;
                      final h = totalMinutes ~/ 60;
                      final m = totalMinutes % 60;
                      return RichText(
                        text: TextSpan(
                          style: AppTextStyles.displayLarge.copyWith(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2,
                          ),
                          children: [
                            TextSpan(text: '$h', style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(text: 'sa ', style: TextStyle(color: AppColors.textTertiary, fontSize: 28, fontWeight: FontWeight.w500)),
                            TextSpan(text: '$m', style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(text: 'dk', style: TextStyle(color: AppColors.textTertiary, fontSize: 28, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toplam Ekran Borcunuz',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Conversion card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.gray100.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gray100),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF13EC5B).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lock_clock_rounded, color: Color(0xFF13EC5B)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Takas Oranı',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Telefonu kilitli tuttuğun her '),
                                    TextSpan(text: '10 dk', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    const TextSpan(text: ' için borcundan '),
                                    TextSpan(text: '5 dk', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF13EC5B))),
                                    const TextSpan(text: ' silinir.'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Preview cards
                  Opacity(
                    opacity: 0.5,
                    child: Row(
                      children: [
                        Expanded(
                          child: _PreviewCard(
                            label: 'Geçen Süre',
                            value: '00:00',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _PreviewCard(
                            label: 'Kazanılan',
                            value: '+${_earnedMinutes.toStringAsFixed(1)} dk',
                            valueColor: const Color(0xFF13EC5B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ÖNİZLEME MODU',
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          // Bottom button
          Padding(
            padding: const EdgeInsets.all(24),
            child: GestureDetector(
              onTap: _startDetox,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF13EC5B),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF13EC5B).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smartphone_rounded, color: const Color(0xFF111813)),
                    const SizedBox(width: 8),
                    Text(
                      'Detoks Modunu Başlat',
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: const Color(0xFF111813),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'Başlattıktan sonra ekranı kilitlemeyi unutmayın.',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveView() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFF13EC5B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DETOKS AKTİF',
                        style: AppTextStyles.overline.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  // Decorative circles
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 288,
                        height: 288,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      Container(
                        width: 340,
                        height: 340,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                      ),
                      // Pulse effect
                      Container(
                        width: 192,
                        height: 192,
                        decoration: BoxDecoration(
                          color: const Color(0xFF13EC5B).withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Timer display
                      Column(
                        children: [
                          Text(
                            'KİLİTLİ SÜRE',
                            style: AppTextStyles.overline.copyWith(
                              color: AppColors.textSecondary,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatTime(_elapsedSeconds),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 72,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: -4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  // Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            icon: Icons.savings_rounded,
                            iconColor: const Color(0xFF13EC5B),
                            value: _earnedMinutes.toStringAsFixed(1),
                            unit: 'dk',
                            label: 'KAZANILAN',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatBox(
                            icon: Icons.timelapse_rounded,
                            iconColor: Colors.grey,
                            value: _formatDebt((_currentDebt?.totalMinutes ?? 0) - _earnedMinutes),
                            label: 'KALAN BORÇ',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Motivational text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 64),
                    child: Text(
                      'Harika gidiyorsun. Telefonundan uzaklaş ve hayatın tadını çıkar.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Stop button
          Padding(
            padding: const EdgeInsets.all(24),
            child: GestureDetector(
              onTap: _stopDetox,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop_circle_rounded, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Text(
                      'Detoksu Bitir',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PreviewCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String? unit;
  final String label;

  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.value,
    this.unit,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              children: [
                TextSpan(text: value),
                if (unit != null)
                  TextSpan(
                    text: unit,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.overline.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
