import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/focus_service.dart';

enum PomodoroState { focus, shortBreak, longBreak }

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  // Pomodoro Ayarları (Dakika)
  static const int focusDuration = 25;
  static const int shortBreakDuration = 5;
  static const int longBreakDuration = 15;
  static const int longBreakInterval = 4; // 4 seans sonra uzun mola

  PomodoroState _currentState = PomodoroState.focus;
  int _remainingSeconds = focusDuration * 60;
  Timer? _timer;
  bool _isRunning = false;
  int _sessionsCompleted = 0;
  final Set<String> _blockedPackages = {};

  @override
  void initState() {
    super.initState();
    _loadFocusSettings();
  }

  Future<void> _loadFocusSettings() async {
    final state = await FocusService.getFocusState();
    if (mounted) {
      setState(() {
        _blockedPackages.addAll(state.blockedPackages);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _deactivateFocusMode();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      _startTimer();
    }
  }

  Future<void> _startTimer() async {
    // Odak seansındaysak bildirim engellemeyi aktif et
    if (_currentState == PomodoroState.focus) {
      bool hasPermission = await FocusService.checkNotificationPermission();
      if (!hasPermission) {
        _showPermissionDialog();
        return;
      }
      await _activateFocusMode();
    }

    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _onSessionComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _deactivateFocusMode();
    setState(() => _isRunning = false);
  }

  void _onSessionComplete() {
    _deactivateFocusMode();
    if (_currentState == PomodoroState.focus) {
      _sessionsCompleted++;
      if (_sessionsCompleted % longBreakInterval == 0) {
        _currentState = PomodoroState.longBreak;
        _remainingSeconds = longBreakDuration * 60;
      } else {
        _currentState = PomodoroState.shortBreak;
        _remainingSeconds = shortBreakDuration * 60;
      }
    } else {
      _currentState = PomodoroState.focus;
      _remainingSeconds = focusDuration * 60;
    }

    setState(() => _isRunning = false);
    _showSessionCompleteDialog();
  }

  Future<void> _activateFocusMode() async {
    final state = FocusModeState(
      isActive: true,
      blockedPackages: _blockedPackages.toList(),
      startTime: DateTime.now(),
    );
    await FocusService.saveFocusState(state);
  }

  Future<void> _deactivateFocusMode() async {
    final state = FocusModeState(
      isActive: false,
      blockedPackages: _blockedPackages.toList(),
    );
    await FocusService.saveFocusState(state);
  }

  void _showSessionCompleteDialog() {
    String title = '';
    String content = '';

    if (_currentState == PomodoroState.focus) {
      title = 'Haydi Başlayalım!';
      content = 'Molan bitti, şimdi odaklanma zamanı.';
    } else {
      title = 'Harika İş!';
      content = _currentState == PomodoroState.longBreak 
          ? '4 seansı tamamladın! Şimdi güzel bir uzun mola ver.' 
          : 'Seansı tamamladın. Kısa bir nefes al.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('TAMAM'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirim Erişimi Gerekli'),
        content: const Text(
          'Pomodoro odak seansında bildirimleri engelleyebilmemiz için "Bildirim Erişimi" izni vermeniz gerekiyor.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              FocusService.requestNotificationPermission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ayarlara Git'),
          ),
        ],
      ),
    );
  }

  String _formatTime() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getThemeColor() {
    switch (_currentState) {
      case PomodoroState.focus: return const Color(0xFFFF5252); // Soft Red
      case PomodoroState.shortBreak: return const Color(0xFF4CAF50); // Green
      case PomodoroState.longBreak: return const Color(0xFF2196F3); // Blue
    }
  }

  String _getStateLabel() {
    switch (_currentState) {
      case PomodoroState.focus: return 'ODAKLAN';
      case PomodoroState.shortBreak: return 'KISA MOLA';
      case PomodoroState.longBreak: return 'UZUN MOLA';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getThemeColor();
    
    return Scaffold(
      backgroundColor: themeColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Seans: $_sessionsCompleted',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cycle Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(longBreakInterval, (index) {
                      bool isCompleted = index < (_sessionsCompleted % longBreakInterval);
                      bool isCurrent = index == (_sessionsCompleted % longBreakInterval) && _currentState == PomodoroState.focus;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.white : (isCurrent ? Colors.white.withOpacity(0.6) : Colors.white.withOpacity(0.2)),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),
                  
                  // State Label
                  Text(
                    _getStateLabel(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Timer
                  Text(
                    _formatTime(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 100,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Play/Pause Button
                  GestureDetector(
                    onTap: _toggleTimer,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: themeColor,
                        size: 64,
                      ),
                    ),
                  ),
                  if (_isRunning) ...[
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _stopTimer,
                      child: const Text(
                        'DURDUR',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Info Footer
            Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                _currentState == PomodoroState.focus 
                    ? 'Bildirimler engellendi. Sadece dikkatini ver.' 
                    : 'Arkana yaslan ve biraz dinlen.',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
