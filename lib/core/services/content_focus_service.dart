import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// İçerik Odaklanma Özelliği - Sosyal medya dikkat dağıtıcı içerikleri engelleme
class ContentFocusRule {
  final String id;
  final String appName;
  final String packageName;
  final String featureName;
  final String description;
  final String iconEmoji;
  final bool isEnabled;

  ContentFocusRule({
    required this.id,
    required this.appName,
    required this.packageName,
    required this.featureName,
    required this.description,
    required this.iconEmoji,
    required this.isEnabled,
  });

  ContentFocusRule copyWith({bool? isEnabled}) {
    return ContentFocusRule(
      id: id,
      appName: appName,
      packageName: packageName,
      featureName: featureName,
      description: description,
      iconEmoji: iconEmoji,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'appName': appName,
    'packageName': packageName,
    'featureName': featureName,
    'description': description,
    'iconEmoji': iconEmoji,
    'isEnabled': isEnabled,
  };

  factory ContentFocusRule.fromJson(Map<String, dynamic> json) {
    return ContentFocusRule(
      id: json['id'],
      appName: json['appName'],
      packageName: json['packageName'],
      featureName: json['featureName'],
      description: json['description'],
      iconEmoji: json['iconEmoji'],
      isEnabled: json['isEnabled'] ?? false,
    );
  }
}

class ContentFocusService {
  static const String _prefsKey = 'content_focus_rules';

  /// Varsayılan kurallar - desteklenen uygulamalar ve özellikler
  static final List<ContentFocusRule> _defaultRules = [
    // YouTube
    ContentFocusRule(
      id: 'youtube_shorts',
      appName: 'YouTube',
      packageName: 'com.google.android.youtube',
      featureName: 'Shorts',
      description: 'Kısa videoları engelle',
      iconEmoji: '📱',
      isEnabled: false,
    ),
    // Instagram
    ContentFocusRule(
      id: 'instagram_reels',
      appName: 'Instagram',
      packageName: 'com.instagram.android',
      featureName: 'Reels',
      description: 'Reels sekmesini engelle',
      iconEmoji: '🎬',
      isEnabled: false,
    ),
    ContentFocusRule(
      id: 'instagram_explore',
      appName: 'Instagram',
      packageName: 'com.instagram.android',
      featureName: 'Keşfet',
      description: 'Keşfet sayfasını engelle',
      iconEmoji: '🔍',
      isEnabled: false,
    ),
    // Twitter (X)
    ContentFocusRule(
      id: 'twitter_foryou',
      appName: 'X (Twitter)',
      packageName: 'com.twitter.android',
      featureName: 'Sana Özel',
      description: 'For You sekmesini engelle',
      iconEmoji: '📰',
      isEnabled: false,
    ),
  ];

  /// Kaydedilmiş kuralları getir
  static Future<List<ContentFocusRule>> getRules() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_prefsKey);
    
    if (jsonStr == null) {
      // İlk sefer - varsayılan kuralları döndür
      return _defaultRules;
    }

    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      final savedRules = jsonList.map((e) => ContentFocusRule.fromJson(e)).toList();
      
      // Yeni eklenen kuralları da ekle (güncelleme durumu)
      final savedIds = savedRules.map((r) => r.id).toSet();
      for (var defaultRule in _defaultRules) {
        if (!savedIds.contains(defaultRule.id)) {
          savedRules.add(defaultRule);
        }
      }
      
      return savedRules;
    } catch (e) {
      return _defaultRules;
    }
  }

  /// Kuralları kaydet
  static Future<void> saveRules(List<ContentFocusRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = json.encode(rules.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsKey, jsonStr);
  }

  /// Tek bir kuralı güncelle
  static Future<void> updateRule(String ruleId, bool isEnabled) async {
    final rules = await getRules();
    final updatedRules = rules.map((r) {
      if (r.id == ruleId) {
        return r.copyWith(isEnabled: isEnabled);
      }
      return r;
    }).toList();
    await saveRules(updatedRules);
  }

  /// Aktif kuralları getir
  static Future<List<ContentFocusRule>> getActiveRules() async {
    final rules = await getRules();
    return rules.where((r) => r.isEnabled).toList();
  }

  /// Belirli bir uygulama için aktif kuralları getir
  static Future<List<ContentFocusRule>> getActiveRulesForApp(String packageName) async {
    final rules = await getActiveRules();
    return rules.where((r) => r.packageName == packageName).toList();
  }

  /// Herhangi bir kural aktif mi?
  static Future<bool> hasActiveRules() async {
    final rules = await getActiveRules();
    return rules.isNotEmpty;
  }

  /// Aktif kural sayısı
  static Future<int> getActiveRuleCount() async {
    final rules = await getActiveRules();
    return rules.length;
  }
}
