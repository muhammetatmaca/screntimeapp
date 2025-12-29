import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';

class FocusModeState {
  final bool isActive;
  final List<String> blockedPackages;
  final DateTime? startTime;

  FocusModeState({
    required this.isActive,
    required this.blockedPackages,
    this.startTime,
  });

  Map<String, dynamic> toJson() => {
    'isActive': isActive,
    'blockedPackages': blockedPackages,
    'startTime': startTime?.toIso8601String(),
  };

  factory FocusModeState.fromJson(Map<String, dynamic> json) => FocusModeState(
    isActive: json['isActive'] ?? false,
    blockedPackages: List<String>.from(json['blockedPackages'] ?? []),
    startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
  );
}

class DetoxDebt {
  final double totalMinutes; // Toplam borç dakikası
  final DateTime lastUpdate;

  DetoxDebt({required this.totalMinutes, required this.lastUpdate});

  Map<String, dynamic> toJson() => {
    'totalMinutes': totalMinutes,
    'lastUpdate': lastUpdate.toIso8601String(),
  };

  factory DetoxDebt.fromJson(Map<String, dynamic> json) => DetoxDebt(
    totalMinutes: (json['totalMinutes'] ?? 0).toDouble(),
    lastUpdate: DateTime.parse(json['lastUpdate'] ?? DateTime.now().toIso8601String()),
  );
}

class FocusService {
  static const String _focusKey = 'focus_mode_state';
  static const String _debtKey = 'detox_debt_state';
  
  // Stream for real-time UI updates
  static final _debtController = StreamController<DetoxDebt>.broadcast();
  static Stream<DetoxDebt> get debtStream => _debtController.stream;

  // --- Odak Modu İşlemleri ---

  static Future<void> saveFocusState(FocusModeState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_focusKey, json.encode(state.toJson()));
  }

  static Future<FocusModeState> getFocusState() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_focusKey);
    if (data == null) return FocusModeState(isActive: false, blockedPackages: []);
    return FocusModeState.fromJson(json.decode(data));
  }

  // --- Borç (Debt) İşlemleri ---

  static Future<DetoxDebt> getDebt() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_debtKey);
    if (data == null) return DetoxDebt(totalMinutes: 0, lastUpdate: DateTime.now());
    return DetoxDebt.fromJson(json.decode(data));
  }

  // --- Bildirim İzni ---
  static const _platform = MethodChannel('com.virelon.spent_time_focus/usage_stats');

  static Future<bool> checkNotificationPermission() async {
    try {
      final bool result = await _platform.invokeMethod('checkNotificationPermission');
      return result;
    } catch (e) {
      return false;
    }
  }

  static Future<void> requestNotificationPermission() async {
    try {
      await _platform.invokeMethod('requestNotificationPermission');
    } catch (e) {
      // ignore
    }
  }

  /// Borç ekleme (Limit aşıldığında çağrılır)
  static Future<void> addDebt(double minutes) async {
    final current = await getDebt();
    final updated = DetoxDebt(
      totalMinutes: current.totalMinutes + minutes,
      lastUpdate: DateTime.now(),
    );
    await _saveDebt(updated);
  }

  /// Borç silme (Detoks yapıldığında çağrılır)
  /// 1 dakika detoks = 0.5 dakika borç siler (2:1 oranı)
  static Future<void> reduceDebt(double detoxMinutes) async {
    final current = await getDebt();
    double reduction = detoxMinutes * 0.5;
    double newTotal = (current.totalMinutes - reduction).clamp(0, double.infinity);
    
    final updated = DetoxDebt(
      totalMinutes: newTotal,
      lastUpdate: DateTime.now(),
    );
    await _saveDebt(updated);
  }

  static Future<void> _saveDebt(DetoxDebt debt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_debtKey, json.encode(debt.toJson()));
    _debtController.add(debt);
  }
}
