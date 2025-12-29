import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Focus Mode Screen - Odak Modu
class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  int _hours = 0;
  int _minutes = 25;
  int _seconds = 0;
  
  bool _isActive = false;
  Timer? _timer;
  int _remainingSeconds = 0;
  
  // App blocking states
  bool _instagramBlocked = true;
  bool _tiktokBlocked = true;
  bool _youtubeBlocked = false;
  bool _snapchatBlocked = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startFocus() {
    int totalSeconds = _hours * 3600 + _minutes * 60 + _seconds;
    if (totalSeconds <= 0) return;
    
    setState(() {
      _isActive = true;
      _remainingSeconds = totalSeconds;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        setState(() => _isActive = false);
        _showCompletionDialog();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _stopFocus() {
    _timer?.cancel();
    setState(() {
      _isActive = false;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF13EC5B)),
            const SizedBox(width: 8),
            const Text('Tebrikler!'),
          ],
        ),
        content: const Text('Odaklanma sürenizi başarıyla tamamladınız.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(color: AppColors.gray100),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Odak Modu',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isActive 
                            ? const Color(0xFF13EC5B).withOpacity(0.1)
                            : const Color(0xFF13EC5B).withOpacity(0.1),
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
                            _isActive ? 'AKTİF' : 'HAZIR',
                            style: AppTextStyles.overline.copyWith(
                              color: const Color(0xFF13EC5B),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hedef Süre',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Timer display
                    _isActive 
                        ? _buildActiveTimer()
                        : _buildTimerPicker(),
                    const SizedBox(height: 32),
                    // Blocked apps section
                    if (!_isActive) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Engellenecekler',
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _instagramBlocked = true;
                                _tiktokBlocked = true;
                                _youtubeBlocked = true;
                                _snapchatBlocked = true;
                              });
                            },
                            child: Text(
                              'Tümünü Seç',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: const Color(0xFF13EC5B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Odak süresince aşağıdaki uygulamalardan bildirim almayacaksınız.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // App list
                      _AppBlockItem(
                        name: 'Instagram',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFCAF45), Color(0xFFFF543E), Color(0xFFC837AB)],
                        ),
                        icon: Icons.camera_alt_rounded,
                        isBlocked: _instagramBlocked,
                        onChanged: (v) => setState(() => _instagramBlocked = v),
                      ),
                      const SizedBox(height: 12),
                      _AppBlockItem(
                        name: 'TikTok',
                        color: Colors.black,
                        icon: Icons.music_note_rounded,
                        isBlocked: _tiktokBlocked,
                        onChanged: (v) => setState(() => _tiktokBlocked = v),
                      ),
                      const SizedBox(height: 12),
                      _AppBlockItem(
                        name: 'YouTube Shorts',
                        color: const Color(0xFFFF0000),
                        icon: Icons.play_arrow_rounded,
                        isBlocked: _youtubeBlocked,
                        onChanged: (v) => setState(() => _youtubeBlocked = v),
                      ),
                      const SizedBox(height: 12),
                      _AppBlockItem(
                        name: 'Snapchat',
                        color: const Color(0xFFFFFC00),
                        icon: Icons.chat_bubble_rounded,
                        iconColor: Colors.black,
                        isBlocked: _snapchatBlocked,
                        onChanged: (v) => setState(() => _snapchatBlocked = v),
                      ),
                    ],
                    if (_isActive)
                      _buildActiveMessage(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom action
      bottomSheet: Container(
        color: Colors.white.withOpacity(0.8),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _isActive ? _stopFocus : _startFocus,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: _isActive ? Colors.red.shade400 : const Color(0xFF13EC5B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (_isActive ? Colors.red : const Color(0xFF13EC5B)).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isActive ? Icons.stop_rounded : Icons.bolt_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isActive ? 'Odaklanmayı Bitir' : 'Odaklanmaya Başla',
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_isActive) ...[
              const SizedBox(height: 12),
              Text(
                'Ayarları Düzenle',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimerPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Hours
        _TimerColumn(
          value: _hours,
          label: 'Saat',
          onIncrement: () => setState(() => _hours = (_hours + 1) % 24),
          onDecrement: () => setState(() => _hours = (_hours - 1 + 24) % 24),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.gray300,
            ),
          ),
        ),
        // Minutes
        _TimerColumn(
          value: _minutes,
          label: 'Dakika',
          onIncrement: () => setState(() => _minutes = (_minutes + 5) % 60),
          onDecrement: () => setState(() => _minutes = (_minutes - 5 + 60) % 60),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Text(
            ':',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.gray300,
            ),
          ),
        ),
        // Seconds
        _TimerColumn(
          value: _seconds,
          label: 'Saniye',
          onIncrement: () => setState(() => _seconds = (_seconds + 10) % 60),
          onDecrement: () => setState(() => _seconds = (_seconds - 10 + 60) % 60),
        ),
      ],
    );
  }

  Widget _buildActiveTimer() {
    int h = _remainingSeconds ~/ 3600;
    int m = (_remainingSeconds % 3600) ~/ 60;
    int s = _remainingSeconds % 60;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _ActiveTimeBox(value: h.toString().padLeft(2, '0'), label: 'Saat'),
        Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Text(':', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.gray300)),
        ),
        _ActiveTimeBox(value: m.toString().padLeft(2, '0'), label: 'Dakika'),
        Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Text(':', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.gray300)),
        ),
        _ActiveTimeBox(value: s.toString().padLeft(2, '0'), label: 'Saniye'),
      ],
    );
  }

  Widget _buildActiveMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF13EC5B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.self_improvement_rounded, color: Color(0xFF13EC5B), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Odaklanma Aktif',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seçili uygulamalardan bildirim almayacaksınız.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
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

class _TimerColumn extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _TimerColumn({
    required this.value,
    required this.label,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 80,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.gray100.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            width: 80,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ActiveTimeBox extends StatelessWidget {
  final String value;
  final String label;

  const _ActiveTimeBox({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.gray100.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AppBlockItem extends StatelessWidget {
  final String name;
  final Color? color;
  final Gradient? gradient;
  final IconData icon;
  final Color iconColor;
  final bool isBlocked;
  final ValueChanged<bool> onChanged;

  const _AppBlockItem({
    required this.name,
    this.color,
    this.gradient,
    required this.icon,
    this.iconColor = Colors.white,
    required this.isBlocked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBlocked 
              ? const Color(0xFF13EC5B).withOpacity(0.3)
              : AppColors.gray100,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              gradient: gradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Toggle
          GestureDetector(
            onTap: () => onChanged(!isBlocked),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isBlocked ? const Color(0xFF13EC5B) : AppColors.gray200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: isBlocked ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
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
          ),
        ],
      ),
    );
  }
}
