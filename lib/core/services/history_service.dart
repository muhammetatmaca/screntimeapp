import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'usage_service.dart';

class HistoryService {
  static const String _fileName = 'usage_history.json';
  static const int _maxDays = 30;

  /// Geçmiş verilerini kaydet ve 30 güne sınırla
  static Future<void> saveDailyData() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');
    
    Map<String, dynamic> history = {};
    
    if (await file.exists()) {
      final content = await file.readAsString();
      try {
        history = jsonDecode(content);
      } catch (e) {
        history = {};
      }
    }

    // Son 7 günü kontrol et ve eksikse doldur (System can only give last 7 days reliably)
    for (int i = 0; i <= 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      // Eğer bu tarih yoksa veya bugünse (bugün her zaman güncellenir)
      if (!history.containsKey(dateStr) || i == 0) {
        final apps = await UsageService.getAppListForDay(i);
        int totalMs = 0;
        Map<String, int> appData = {};
        
        for (var app in apps) {
          totalMs += app.usage.inMilliseconds;
          // Sadece anlamlı kullanımı olanları tut (örn: 10 saniye üstü)
          if (app.usage.inSeconds > 10) {
            appData[app.packageName] = app.usage.inMilliseconds;
          }
        }
        
        history[dateStr] = {
          'totalUsageMs': totalMs,
          'apps': appData,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
      }
    }

    // 30 günden fazlasını sil
    var sortedKeys = history.keys.toList()..sort();
    if (sortedKeys.length > _maxDays) {
      final keysToRemove = sortedKeys.sublist(0, sortedKeys.length - _maxDays);
      for (var key in keysToRemove) {
        history.remove(key);
      }
    }

    // Kaydet
    await file.writeAsString(jsonEncode(history));
    
    // Kullanıcın istediği .md raporunu da oluştur
    await _generateMarkdownReport(history);
  }

  /// Okunabilir .md raporu oluştur
  static Future<void> _generateMarkdownReport(Map<String, dynamic> history) async {
    try {
      final directory = await getExternalStorageDirectory(); // Downloads/Documents gibi bir yer için
      if (directory == null) return;
      
      final reportFile = File('${directory.path}/usage_history_report.md');
      StringBuffer sb = StringBuffer();
      
      sb.writeln("# 📱 30 Günlük Uygulama Kullanım Raporu");
      sb.writeln("Son güncelleme: ${DateTime.now().toString()}");
      sb.writeln("");

      var sortedKeys = history.keys.toList()..sort((a, b) => b.compareTo(a)); // Yeniden eskiye
      
      for (var date in sortedKeys) {
        final data = history[date];
        final totalMin = (data['totalUsageMs'] as int) ~/ 60000;
        final hours = totalMin ~/ 60;
        final mins = totalMin % 60;
        
        sb.writeln("## 📅 Tarih: $date");
        sb.writeln("**Toplam Kullanım:** $hours saat $mins dakika");
        sb.writeln("");
        sb.writeln("| Uygulama (Paket) | Süre (Dakika) |");
        sb.writeln("| :--- | :--- |");
        
        final apps = data['apps'] as Map<String, dynamic>;
        // Süreye göre sırala
        var sortedApps = apps.entries.toList()..sort((a, b) => (b.value as int).compareTo(a.value as int));
        
        for (var app in sortedApps.take(10)) { // İlk 10 uygulamayı yaz
          final appMin = (app.value as int) ~/ 60000;
          if (appMin > 0) {
            sb.writeln("| ${app.key} | $appMin dk |");
          }
        }
        sb.writeln("");
        sb.writeln("---");
        sb.writeln("");
      }
      
      await reportFile.writeAsString(sb.toString());
    } catch (e) {
      // Log for debug if needed
    }
  }

  /// Geçmiş verilerini getir
  static Future<Map<String, dynamic>> getHistory() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');
    
    if (await file.exists()) {
      final content = await file.readAsString();
      try {
        return jsonDecode(content);
      } catch (e) {
        return {};
      }
    }
    return {};
  }

  /// Son 30 günlük toplam kullanım verisini grafik için getir
  static Future<List<double>> getLast30DaysTotals() async {
    final history = await getHistory();
    List<double> totals = [];
    final now = DateTime.now();
    
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      if (history.containsKey(dateStr)) {
        totals.add((history[dateStr]['totalUsageMs'] as int) / 3600000.0); // Saat cinsinden
      } else {
        totals.add(0.0);
      }
    }
    return totals;
  }

  /// Son 7 günlük uygulama bazlı toplam kullanımı getir
  static Future<Map<String, int>> getWeeklyAppAggregation() async {
    final history = await getHistory();
    Map<String, int> aggregation = {};
    final now = DateTime.now();
    
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      if (history.containsKey(dateStr)) {
        final apps = history[dateStr]['apps'] as Map<String, dynamic>;
        apps.forEach((pkg, ms) {
          aggregation[pkg] = (aggregation[pkg] ?? 0) + (ms as int);
        });
      }
    }
    return aggregation;
  }

  /// Haftalık analiz için verileri getir (Bu hafta vs geçen hafta)
  static Future<Map<String, dynamic>> getWeeklyAnalysis() async {
    final history = await getHistory();
    final now = DateTime.now();
    
    int thisWeekMs = 0;
    int lastWeekMs = 0;
    
    // Bu hafta (Son 7 gün)
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      if (history.containsKey(dateStr)) {
        thisWeekMs += history[dateStr]['totalUsageMs'] as int;
      }
    }
    
    // Geçen hafta (8-14 gün arası)
    for (int i = 7; i < 14; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      if (history.containsKey(dateStr)) {
        lastWeekMs += history[dateStr]['totalUsageMs'] as int;
      }
    }
    
    double change = 0;
    if (lastWeekMs > 0) {
      change = ((thisWeekMs - lastWeekMs) / lastWeekMs) * 100;
    }
    
    return {
      'thisWeekMs': thisWeekMs,
      'lastWeekMs': lastWeekMs,
      'change': change,
    };
  }

  /// Mevcut seriyi ve hedef durumunu getir
  static Future<Map<String, dynamic>> getStreakData() async {
    final history = await getHistory();
    final now = DateTime.now();
    int streak = 0;
    const int dailyGoalMs = 4 * 3600000; // 4 saat hedef

    // Bugünden geriye doğru say
    for (int i = 0; i < 30; i++) {
       final date = now.subtract(Duration(days: i));
       final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
       
       if (history.containsKey(dateStr)) {
         final usageMs = history[dateStr]['totalUsageMs'] as int;
         if (usageMs <= dailyGoalMs) {
           streak++;
         } else {
           // Hedef aşılmış, seri burada biter
           break;
         }
       } else if (i == 0) {
         // Eğer bugün dosyada henüz yoksa ama biz şu an bakıyorsak, 
         // bugünü başlangıç (1) olarak kabul edebiliriz (eğer şu anki kullanım hedef altındaysa)
         // Ancak yukarıda saveDailyData'yı await ettiğimiz için buraya girmemeli.
         // Yine de fallback olarak kalsın.
         streak = 1; 
       } else {
         // Arada boşluk var (örn: dün uygulama açılmamış), seri bozulur
         break;
       }
    }

    return {
      'streak': streak,
      'goalHours': 4,
    };
  }

  /// Takvim için günlük durumları getir
  static Future<Map<String, int>> getCalendarData() async {
    final history = await getHistory();
    const int dailyGoalMs = 4 * 3600000;
    Map<String, int> calendar = {};

    history.forEach((date, data) {
      if ((data['totalUsageMs'] as int) <= dailyGoalMs) {
        calendar[date] = 1; // Başarılı
      } else {
        calendar[date] = 2; // Başarısız
      }
    });

    return calendar;
  }
}
