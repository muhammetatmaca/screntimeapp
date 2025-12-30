import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:flutter/foundation.dart';
import 'limit_service.dart';
import 'focus_service.dart';
import 'package:permission_handler/permission_handler.dart';

class AppUsageRecord {
  final String packageName;
  final Duration usage;
  String? appName;
  String? iconBase64;
  Uint8List? iconBytes;
  
  AppUsageRecord({
    required this.packageName, 
    required this.usage,
    this.appName,
    this.iconBase64,
  }) {
    if (iconBase64 != null && iconBase64!.isNotEmpty) {
      try {
        iconBytes = base64Decode(iconBase64!);
      } catch (e) {
        iconBytes = null;
      }
    }
  }
}

/// Kaydırma mesafesi sonucu
class ScrollDistanceResult {
  final double totalMeters;
  final Map<String, double> appDistances;
  final String comparisonText;
  final String comparisonEmoji;

  ScrollDistanceResult({
    required this.totalMeters,
    required this.appDistances,
    required this.comparisonText,
    required this.comparisonEmoji,
  });

  /// Toplam mesafeyi formatla
  String get formattedDistance {
    if (totalMeters >= 1000) {
      return '${(totalMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${totalMeters.toStringAsFixed(0)} m';
  }
}

class UsageService {
  static const platform = MethodChannel('com.virelon.spent_time_focus/usage_stats');

  /// Tüm yüklü uygulamaları getir
  static Future<List<Map<String, String>>> getInstalledApps() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getInstalledApps');
      return result.map((item) => {
        'packageName': item['packageName'] as String,
        'appName': item['appName'] as String,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> checkAndRequestPermission() async {
    // 1. Kullanım İstatistikleri İzni
    bool? isUsageGranted = await UsageStats.checkUsagePermission();
    if (isUsageGranted == false) {
      await UsageStats.grantUsagePermission();
    }

    // 2. Bildirim İzni (Android 13+)
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    return isUsageGranted ?? false;
  }

  /// Belirli bir tarih aralığı için toplam kullanımı döndürür
  static Future<Duration> getTodayTotalUsage({DateTime? startDate, DateTime? endDate}) async {
    final appUsageMap = await _getAppUsageMap(startDate: startDate, endDate: endDate);
    int totalMs = 0;
    appUsageMap.forEach((key, value) => totalMs += value);
    return Duration(milliseconds: totalMs);
  }

  /// Belirli bir uygulama için kullanım süresini döndürür
  static Future<Duration> getUsageForApp(String nameOrPackage, {DateTime? startDate, DateTime? endDate}) async {
    final appUsageMap = await _getAppUsageMap(startDate: startDate, endDate: endDate);
    for (var entry in appUsageMap.entries) {
      if (entry.key.toLowerCase().contains(nameOrPackage.toLowerCase())) {
        return Duration(milliseconds: entry.value);
      }
    }
    return Duration.zero;
  }

  /// Belirli bir tarih aralığı için uygulama listesini döndürür
  /// withAppInfo: true ise uygulama adı ve ikonu da getirilir
  static Future<List<AppUsageRecord>> getTodayAppList({
    DateTime? startDate, 
    DateTime? endDate,
    bool withAppInfo = false,
  }) async {
    final appUsageMap = await _getAppUsageMap(startDate: startDate, endDate: endDate);
    List<AppUsageRecord> list = [];
    
    for (var entry in appUsageMap.entries) {
      if (entry.value > 0) {
        String? appName;
        String? iconBase64;
        
        if (withAppInfo) {
          final info = await getAppInfo(entry.key);
          appName = info['appName'] as String?;
          iconBase64 = info['iconBase64'] as String?;
        }
        
        list.add(AppUsageRecord(
          packageName: entry.key, 
          usage: Duration(milliseconds: entry.value),
          appName: appName,
          iconBase64: iconBase64,
        ));
      }
    }
    
    list.sort((a, b) => b.usage.compareTo(a.usage));
    
    // Uygulama listesi alınırken borçları da güncelle
    _checkAndSyncDebts(list);
    
    return list;
  }

  /// Limit aşımı varsa borç olarak kaydet
  static Future<void> _checkAndSyncDebts(List<AppUsageRecord> currentUsage) async {
    final limits = await LimitService.getLimits();
    if (limits.isEmpty) return;

    double newDebtMinutes = 0;
    
    for (var limit in limits) {
      final usage = currentUsage.firstWhere(
        (u) => u.packageName == limit.packageName,
        orElse: () => AppUsageRecord(packageName: limit.packageName, usage: Duration.zero),
      );

      if (usage.usage.inMinutes > limit.limitMinutes) {
        // Aşılan süreyi hesapla
        int overMinutes = usage.usage.inMinutes - limit.limitMinutes;
        // Bu paket için daha önce ne kadar borç eklediğimizi bilmemiz lazım 
        // Ama şimdilik basitçe toplam borcu güncelleyen bir mantık kuruyoruz.
        // NOT: Gerçek uygulamada "bugün eklenen borç" olarak takip edilmeli.
      }
    }
    // TODO: Borç senkronizasyon mantığı daha detaylı geliştirilebilir.
  }

  /// Uygulama bilgisini getirir (ad + ikon)
  static Future<Map<String, dynamic>> getAppInfo(String packageName) async {
    try {
      final result = await platform.invokeMethod('getAppInfo', {'packageName': packageName});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      // Daha iyi bir fallback ismi oluştur
      final parts = packageName.split('.');
      String fallbackName = parts.last;
      if (fallbackName.toLowerCase() == 'android' && parts.length > 2) {
        fallbackName = parts[parts.length - 2];
      }
      fallbackName = fallbackName[0].toUpperCase() + fallbackName.substring(1);
      
      return {
        'packageName': packageName,
        'appName': fallbackName,
        'iconBase64': null,
      };
    }
  }

  /// Sadece uygulama adını getirir
  static Future<String> getAppName(String packageName) async {
    try {
      final result = await platform.invokeMethod('getAppName', {'packageName': packageName});
      return result as String;
    } catch (e) {
      return packageName.split('.').last;
    }
  }

  /// Sadece uygulama ikonunu Base64 olarak getirir
  static Future<String?> getAppIcon(String packageName) async {
    try {
      final result = await platform.invokeMethod('getAppIcon', {'packageName': packageName});
      return result as String?;
    } catch (e) {
      return null;
    }
  }

  /// Belirli bir gün için uygulama kullanım listesini döndürür
  /// daysAgo: 0 = bugün, 1 = dün, 2 = önceki gün, vs.
  /// withAppInfo: true ise uygulama adı ve ikonu da getirilir
  static Future<List<AppUsageRecord>> getAppListForDay(int daysAgo, {bool withAppInfo = false}) async {
    DateTime now = DateTime.now();
    DateTime targetDay = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
    DateTime nextDay = targetDay.add(const Duration(days: 1));
    
    // Eğer bugün ise, bitiş zamanı şu an olsun
    DateTime endTime = daysAgo == 0 ? now : nextDay;
    
    return getTodayAppList(startDate: targetDay, endDate: endTime, withAppInfo: withAppInfo);
  }

  /// Belirli bir gün için toplam kullanımı döndürür
  static Future<Duration> getTotalUsageForDay(int daysAgo) async {
    DateTime now = DateTime.now();
    DateTime targetDay = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysAgo));
    DateTime nextDay = targetDay.add(const Duration(days: 1));
    
    DateTime endTime = daysAgo == 0 ? now : nextDay;
    
    return getTodayTotalUsage(startDate: targetDay, endDate: endTime);
  }

  /// Uygulama kategorisine göre dakika başına kaydırma mesafesi (metre)
  /// Gerçekçi değerler: Ekran ~15cm, dakikada ~20 kaydırma, %50 aktif kaydırma
  static const Map<String, double> _scrollRatesPerMinute = {
    // Sosyal Medya - Yüksek kaydırma (feed akışı)
    'com.instagram.android': 5.0,
    'com.zhiliaoapp.musically': 2.0, // TikTok (video izleme, az kaydırma)
    'com.ss.android.ugc.trill': 2.0, // TikTok alternatif
    'com.twitter.android': 4.0,
    'com.facebook.katana': 4.5,
    'com.facebook.orca': 3.0, // Messenger (mesajlaşma, orta)
    'com.whatsapp': 2.5,
    'org.telegram.messenger': 2.5,
    'com.snapchat.android': 3.0,
    'com.linkedin.android': 3.0,
    'com.pinterest': 4.0,
    'com.reddit.frontpage': 4.5,
    'com.tumblr': 4.0,
    
    // Video/Streaming - Çok düşük kaydırma (izleme ağırlıklı)
    'com.google.android.youtube': 1.5,
    'com.netflix.mediaclient': 0.5,
    'com.amazon.avod.thirdpartyclient': 0.5, // Prime Video
    'com.disney.disneyplus': 0.5,
    'tv.twitch.android.app': 1.0,
    'com.spotify.music': 1.0,
    
    // Haber/Okuma - Orta kaydırma
    'com.google.android.apps.magazines': 3.0, // Google News
    'flipboard.app': 3.5,
    'com.medium.reader': 2.5,
    
    // Alışveriş - Orta-yüksek kaydırma (ürün listesi)
    'com.amazon.mShop.android.shopping': 3.5,
    'com.trendyol.trendyolapp': 4.0,
    'com.hepsiburada': 4.0,
    'com.n11.android': 3.5,
    'com.alibaba.aliexpresshd': 4.0,
    
    // Oyunlar - Düşük kaydırma
    'default_game': 1.0,
    
    // Diğer - Varsayılan
    'default': 2.0,
  };

  /// Oyun paket isimlerini tanımla
  static const List<String> _gamePackagePatterns = [
    'game', 'games', 'play', 'puzzle', 'arcade', 'casino', 
    'racing', 'shooter', 'rpg', 'strategy', 'sports',
    'com.supercell', 'com.king', 'com.rovio', 'com.ea.', 
    'com.gameloft', 'com.nintendo', 'com.epicgames',
    'com.innersloth', 'com.mojang', 'com.roblox',
  ];

  /// Paket adına göre kaydırma oranını al
  static double _getScrollRateForPackage(String packageName) {
    // Önce tam eşleşme ara
    if (_scrollRatesPerMinute.containsKey(packageName)) {
      return _scrollRatesPerMinute[packageName]!;
    }
    
    // Oyun mu kontrol et
    String lowerPackage = packageName.toLowerCase();
    for (var pattern in _gamePackagePatterns) {
      if (lowerPackage.contains(pattern)) {
        return _scrollRatesPerMinute['default_game']!;
      }
    }
    
    // Varsayılan oran
    return _scrollRatesPerMinute['default']!;
  }

  /// Belirli bir gün için tahmini kaydırma mesafesini hesapla
  static Future<ScrollDistanceResult> getEstimatedScrollDistance(int daysAgo) async {
    final apps = await getAppListForDay(daysAgo);
    
    double totalMeters = 0;
    Map<String, double> appScrollDistances = {};
    
    for (var app in apps) {
      double minutes = app.usage.inSeconds / 60.0;
      double scrollRate = _getScrollRateForPackage(app.packageName);
      double distance = minutes * scrollRate;
      
      totalMeters += distance;
      appScrollDistances[app.packageName] = distance;
    }
    
    return ScrollDistanceResult(
      totalMeters: totalMeters,
      appDistances: appScrollDistances,
      comparisonText: _getScrollComparison(totalMeters),
      comparisonEmoji: _getScrollEmoji(totalMeters),
    );
  }

  /// Kaydırma mesafesini eğlenceli karşılaştırmaya çevir
  static String _getScrollComparison(double meters) {
    // Ölçüler:
    // Basketbol potası = 3 metre
    // Zürafa = 5.5 metre
    // Çift katlı otobüs = 4.5 metre
    // Mavi balina = 25 metre
    // Özgürlük Heykeli = 93 metre
    // Big Ben = 96 metre
    // Galata Kulesi = 67 metre
    // Pisa Kulesi = 56 metre
    // Eyfel Kulesi = 330 metre
    // Futbol sahası uzunluğu = 105 metre
    // Olimpik yüzme havuzu = 50 metre
    // Maratonun çeyreği = 10.5 km
    
    if (meters < 10) {
      double hoops = meters / 3;
      if (hoops < 1) return '${meters.toStringAsFixed(0)} metre';
      return '${hoops.toStringAsFixed(0)} basketbol potası';
    } else if (meters < 25) {
      double giraffes = meters / 5.5;
      return '${giraffes.toStringAsFixed(0)} zürafa boyu';
    } else if (meters < 50) {
      double whales = meters / 25;
      return '${whales.toStringAsFixed(1)} mavi balina';
    } else if (meters < 100) {
      double pools = meters / 50;
      return '${pools.toStringAsFixed(1)} olimpik havuz';
    } else if (meters < 200) {
      double statues = meters / 93;
      return '${statues.toStringAsFixed(1)} Özgürlük Heykeli';
    } else if (meters < 400) {
      double galata = meters / 67;
      return '${galata.toStringAsFixed(0)} Galata Kulesi';
    } else if (meters < 800) {
      double eiffel = meters / 330;
      return '${eiffel.toStringAsFixed(1)} Eyfel Kulesi';
    } else if (meters < 2000) {
      int fields = (meters / 105).floor();
      return '$fields futbol sahası';
    } else if (meters < 5000) {
      double burj = meters / 828;
      return '${burj.toStringAsFixed(1)} Burj Khalifa';
    } else if (meters < 10000) {
      double km = meters / 1000;
      return '${km.toStringAsFixed(1)} km yürüyüş';
    } else {
      double marathon = meters / 42195;
      if (marathon < 0.5) {
        return '${(meters / 1000).toStringAsFixed(1)} km koşu';
      }
      return '${marathon.toStringAsFixed(2)} maraton';
    }
  }

  static String _getScrollEmoji(double meters) {
    if (meters < 10) return '🏀';
    if (meters < 25) return '🦒';
    if (meters < 50) return '🐋';
    if (meters < 100) return '🏊';
    if (meters < 200) return '🗽';
    if (meters < 400) return '🏰';
    if (meters < 800) return '🗼';
    if (meters < 2000) return '⚽';
    if (meters < 5000) return '🏙️';
    if (meters < 10000) return '🚶';
    return '🏃';
  }

  static String _formatDuration(int ms) {
    int minutes = ms ~/ 60000;
    int seconds = (ms % 60000) ~/ 1000;
    return "$minutes dk $seconds sn";
  }

  static Future<Map<String, int>> _getAppUsageMap({DateTime? startDate, DateTime? endDate}) async {
    try {
      if (Platform.isAndroid) {
        bool? isPermissionGranted = await UsageStats.checkUsagePermission();
        if (isPermissionGranted == false) return {};

        DateTime now = DateTime.now();
        DateTime todayMidnight = startDate ?? DateTime(now.year, now.month, now.day);
        DateTime queryEnd = endDate ?? now;

        Map<String, int> finalUsageMap = {};

        try {
          // Kullanım verilerini al
          final Map<dynamic, dynamic> nativeResult = await platform.invokeMethod(
            'getDailyUsageStats',
            {
              'startTime': todayMidnight.millisecondsSinceEpoch,
              'endTime': queryEnd.millisecondsSinceEpoch,
            },
          );

          nativeResult.forEach((key, value) {
            String pkg = key.toString();
            int ms = (value as num).toInt();
            
            if (ms > 0) {
              finalUsageMap[pkg] = ms;
            }
          });

        } catch (e) {
          if (kDebugMode) print("## Native API Hatası: $e");
        }

        // Sistem uygulamalarını filtrele
        const List<String> excluded = [
          'com.miui.home', 
          'com.android.systemui', 
          'com.google.android.gms',
          'android', 
          'com.android.settings',
          'com.pozitron.iscep',
          'com.google.android.apps.wellbeing',
          'com.google.android.gm',
          'com.android.vending',
          'com.google.android.googlequicksearchbox',
          'com.miui.securitycenter',
          'com.android.providers.downloads.ui',
          'com.android.chrome',
          'com.google.android.inputmethod.latin',
          'com.google.android.deskclock',
          'com.google.android.calculator',
          'com.sec.android.app.launcher',
          'com.huawei.android.launcher',
        ];
        
        finalUsageMap.removeWhere((pkg, ms) {
          String lowerPkg = pkg.toLowerCase();
          return excluded.contains(pkg) || 
              lowerPkg.contains('launcher') ||
              lowerPkg.contains('wellbeing') ||
              lowerPkg.contains('systemui') ||
              lowerPkg.contains('inputmethod') ||
              lowerPkg.contains('keyboard') ||
              lowerPkg.contains('settings') ||
              lowerPkg.contains('provider') ||
              pkg.startsWith('com.android.') ||
              pkg.startsWith('com.miui.') ||
              pkg.startsWith('com.qualcomm.') ||
              pkg.startsWith('com.sec.android.') ||
              pkg.startsWith('com.huawei.') ||
              pkg.startsWith('com.samsung.') ||
              pkg.startsWith('com.google.android.gms') ||
              pkg.startsWith('com.google.android.ext.') ||
              pkg.startsWith('com.google.android.providers.') ||
              // Sadece "android" olan veya android ile biten paketler
              pkg == 'android' ||
              (pkg.split('.').last == 'android' && !pkg.contains('twitter') && !pkg.contains('instagram'));
        });

        return finalUsageMap;
      }
      return {};
    } catch (e) {
      if (kDebugMode) print("Usage Service Error: $e");
      return {};
    }
  }
}
