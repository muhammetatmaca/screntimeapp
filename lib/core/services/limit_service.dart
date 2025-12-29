import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppLimit {
  final String packageName;
  final String appName;
  final int limitMinutes;

  AppLimit({
    required this.packageName,
    required this.appName,
    required this.limitMinutes,
  });

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'limitMinutes': limitMinutes,
  };

  factory AppLimit.fromJson(Map<String, dynamic> json) => AppLimit(
    packageName: json['packageName'],
    appName: json['appName'],
    limitMinutes: json['limitMinutes'],
  );
}

class LimitService {
  static const String _storageKey = 'app_limits';

  /// Tüm limitleri getir
  static Future<List<AppLimit>> getLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final String? limitsJson = prefs.getString(_storageKey);
    
    if (limitsJson == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(limitsJson);
      return decoded.map((item) => AppLimit.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Limit ekle veya güncelle
  static Future<void> saveLimit(AppLimit limit) async {
    final prefs = await SharedPreferences.getInstance();
    List<AppLimit> limits = await getLimits();
    
    // Varsa sil, yenisini ekle
    limits.removeWhere((l) => l.packageName == limit.packageName);
    limits.add(limit);
    
    await prefs.setString(_storageKey, jsonEncode(limits.map((l) => l.toJson()).toList()));
  }

  /// Limit sil
  static Future<void> deleteLimit(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    List<AppLimit> limits = await getLimits();
    
    limits.removeWhere((l) => l.packageName == packageName);
    
    await prefs.setString(_storageKey, jsonEncode(limits.map((l) => l.toJson()).toList()));
  }
}
