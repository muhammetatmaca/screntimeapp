import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../onboarding/presentation/widgets/onboarding_buttons.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../focus/presentation/screens/focus_mode_screen.dart';
import '../../../focus/presentation/screens/detox_screen.dart';
import '../../../focus/presentation/screens/pomodoro_screen.dart';
import '../../data/home_data.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/app_limit_card.dart';
import '../widgets/bottom_nav_bar.dart';
import 'app_detail_screen.dart';
import 'add_limit_screen.dart';
import '../widgets/monthly_chart.dart';
import '../../../../core/services/limit_service.dart';
import '../../../invoice/presentation/screens/invoice_screen.dart';
import '../../../invoice/presentation/screens/widget_settings_screen.dart';
import '../../../../core/services/usage_service.dart';
import '../../../../core/services/history_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/widget_service.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// Main home screen with usage summary
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isInitializing = false;
  int _selectedTabIndex = 0; // 0: Günlük, 1: Haftalık, 2: Aylık
  int _bottomNavIndex = 0;
  bool _showFocusMenu = false;
  Duration _currentUsage = Duration.zero;
  List<DailyUsageData> _weeklyData = [];
  List<AppUsageRecord> _selectedDayApps = [];
  int _selectedDayIndex = 6; // Varsayılan: Bugün (son gün)
  bool _isLoading = true;
  final Map<int, List<AppUsageRecord>> _cachedDayApps = {}; // Geçmiş günler için cache
  List<AppUsageData> _dynamicLimits = [];
  bool _isRoutineSet = false;
  double _lifeBatteryPercentage = 1.0;
  Duration _remainingFreeTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _initializeData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Ayarlardan geri dönüldüğünde veya uygulama öne geldiğinde verileri tazele
      _initializeData();
    }
  }

  Future<void> _initializeData() async {
    if (_isInitializing) return;
    _isInitializing = true;
    
    _cachedDayApps.clear();
    setState(() => _isLoading = true);
    
    // İzin kontrolü ve isteme
    bool hasPermission = await UsageService.checkAndRequestPermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitializing = false;
        });
      } else {
        _isInitializing = false;
      }
      return;
    }

    // 30 günlük geçmişi kaydet/güncelle (Bitmesini bekle ki seri doğru gelsin)
    await HistoryService.saveDailyData();

    await _loadDynamicLimits();
    await _loadLifeBatteryData();
    await _loadWeeklyData();
    await _loadAppsForDay(_selectedDayIndex);
    
    // Widget'ları güncelle
    if (_weeklyData.isNotEmpty) {
      final todayUsage = _weeklyData.last.usageTime;
      final hours = todayUsage.inHours;
      final mins = todayUsage.inMinutes % 60;
      
      // Kullanım Widgetı
      await WidgetService.updateUsageWidget(
        usageTime: '${hours}s ${mins}dk',
        status: 'Spent: Odaklandın',
      );

      // Pil Widgetı
      await WidgetService.updateBatteryWidget(
        percentage: '%${(_lifeBatteryPercentage * 100).toInt()}',
      );

      // Kaydırma Widgetı
      final scroll = await UsageService.getEstimatedScrollDistance(0);
      await WidgetService.updateScrollWidget(
          distance: scroll.formattedDistance,
          comparison: scroll.comparisonText,
      );

      // Takvim Widgetı
      final now = DateTime.now();
      final months = ['OCAK', 'ŞUBAT', 'MART', 'NİSAN', 'MAYIS', 'HAZİRAN', 'TEMMUZ', 'AĞUSTOS', 'EYLÜL', 'EKİM', 'KASIM', 'ARALIK'];
      final weekdays = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
      await WidgetService.updateCalendarWidget(
        day: now.day.toString(),
        month: months[now.month - 1],
        weekday: weekdays[now.weekday - 1],
      );

      // Top Uygulamalar Widgetı
      final topApps = await UsageService.getTodayAppList();
      if (topApps.isNotEmpty) {
        String formatApp(int index) {
          if (index >= topApps.length) return '${index + 1}. -';
          final app = topApps[index];
          return '${index + 1}. ${app.packageName.split('.').last} - ${app.usage.inMinutes}dk';
        }
        await WidgetService.updateTopAppsWidget(
          app1: formatApp(0),
          app2: formatApp(1),
          app3: formatApp(2),
        );
      }

      // Pomodoro Widgetı (Statik başlangıç verisi veya mevcut servis entegrasyonu)
      await WidgetService.updatePomodoroWidget(
        timer: '25:00',
        status: 'ODAKLANMA',
        sessions: 'Seans: 0/4',
      );

      // Fatura Widgetı
      await WidgetService.updateBillWidget(
        item1: 'En Çok: ${topApps.isNotEmpty ? topApps.first.packageName.split('.').last : "-"}',
        total: 'TOPLAM: ${hours}s ${mins}dk',
      );

      // Detoks Widgetı (Focus modu açıksa aktif göster)
      await WidgetService.updateDetoxWidget(
        status: 'HAZIR',
        desc: 'Odaklanmaya başla',
      );
    }

    if (mounted) {
      setState(() {
        _currentUsage = _weeklyData.isNotEmpty 
            ? _weeklyData[_selectedDayIndex].usageTime 
            : Duration.zero;
        _isLoading = false;
        _isInitializing = false;
      });
    } else {
      _isInitializing = false;
    }
  }

  Future<void> _loadWeeklyData() async {
    List<DailyUsageData> weekData = [];
    final now = DateTime.now();
    final dayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final start = DateTime(date.year, date.month, date.day);
      final end = (i == 0) ? now : DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final usage = await UsageService.getTodayTotalUsage(startDate: start, endDate: end);
      
      // Haftanın gününü bul (0=Monday in Dart, but dayLabels matches)
      // date.weekday returns 1-7 (1=Mon)
      int weekdayIndex = date.weekday - 1;
      
      weekData.add(DailyUsageData(
        dayLabel: dayLabels[weekdayIndex],
        usageTime: usage,
        isSelected: i == 0,
      ));
    }
    
    if (mounted) {
      setState(() {
        _weeklyData = weekData;
      });
    }
  }

  Future<void> _loadAppsForDay(int index) async {
    final now = DateTime.now();
    final date = now.subtract(Duration(days: 6 - index));
    final start = DateTime(date.year, date.month, date.day);
    final end = (index == 6) ? now : DateTime(date.year, date.month, date.day, 23, 59, 59);

    // Eğer bugün değilse ve cache'de varsa oradan oku
    if (index != 6 && _cachedDayApps.containsKey(index)) {
      if (mounted) {
        setState(() {
          _selectedDayApps = _cachedDayApps[index]!;
          _selectedDayIndex = index;
          _updateWeeklyDataSelection(index);
        });
      }
      return;
    }

    final apps = await UsageService.getTodayAppList(startDate: start, endDate: end);
    
    // Geçmiş günü cache'le
    if (index != 6) {
      _cachedDayApps[index] = apps;
    }
    
    if (mounted) {
      setState(() {
        _selectedDayApps = apps;
        _selectedDayIndex = index;
        _updateWeeklyDataSelection(index);
      });
    }
  }

  void _updateWeeklyDataSelection(int index) {
    for (int i = 0; i < _weeklyData.length; i++) {
      _weeklyData[i] = DailyUsageData(
        dayLabel: _weeklyData[i].dayLabel,
        usageTime: _weeklyData[i].usageTime,
        isSelected: i == index,
        isOverLimit: _weeklyData[i].isOverLimit,
      );
    }
    _currentUsage = _weeklyData[index].usageTime;
  }

  Future<void> _loadUsage() async {
    // _initializeData zaten bu işi yapıyor
  }

  Future<void> _loadDynamicLimits() async {
    final limits = await LimitService.getLimits();
    final todayUsage = await UsageService.getAppListForDay(0);
    
    final Map<String, Duration> usageMap = {
      for (var app in todayUsage) app.packageName: app.usage
    };

    List<AppUsageData> mappedLimits = [];
    for (var limit in limits) {
      mappedLimits.add(AppUsageData(
        appName: limit.appName,
        iconType: limit.packageName, // Paket adını kullanarak ikon çekeceğiz
        usageTime: usageMap[limit.packageName] ?? Duration.zero,
        limitTime: Duration(minutes: limit.limitMinutes),
      ));
    }

    if (mounted) {
      setState(() {
        _dynamicLimits = mappedLimits;
      });
    }
  }

  Future<void> _loadLifeBatteryData() async {
    final isSet = await SettingsService.isSetupDone();
    final sleepHours = await SettingsService.getSleepHours();
    final workHours = await SettingsService.getWorkHours();
    
    // Toplam usage (bugün)
    final todayUsage = await UsageService.getTodayTotalUsage();
    
    const double totalDayMinutes = 24 * 60;
    final double sleepMinutes = sleepHours * 60;
    final double workMinutes = workHours * 60;
    final double usageMinutes = todayUsage.inMinutes.toDouble();
    
    final double availableMinutes = totalDayMinutes - sleepMinutes - workMinutes;
    final double remainingMinutes = (availableMinutes - usageMinutes).clamp(0, availableMinutes);
    
    if (mounted) {
      setState(() {
        _isRoutineSet = isSet;
        _remainingFreeTime = Duration(minutes: remainingMinutes.toInt());
        _lifeBatteryPercentage = availableMinutes > 0 ? remainingMinutes / availableMinutes : 0;
      });
    }
  }

  void _onBottomNavTap(int index) {
    if (index == 1) {
      // Fatura sayfasına git
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const InvoiceScreen(),
        ),
      );
    } else if (index == 2) {
      setState(() => _showFocusMenu = !_showFocusMenu);
    } else if (index == 3) {
      // Widget Ayarları sayfasına git
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const WidgetSettingsScreen(),
        ),
      );
    } else if (index == 4) {
      // Profil - Settings sayfasına git
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SettingsScreen(),
        ),
      ).then((_) {
        // Ayarlardan geri dönüldüğünde verileri tazele (örneğin günlük hedef değişmiş olabilir)
        _initializeData();
      });
    } else {
      setState(() => _bottomNavIndex = index);
    }
  }

  void _openDetoxMode() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DetoxScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              _buildHeader(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Don't Break the Chain (En üstte)
                      _buildChainSection(),
                      // Total usage display
                      _buildTotalUsageSection(),
                      // Weekly chart
                      _buildChartSection(),
                      // Daily App List (Seçilen güne göre)
                      _buildDailyAppListSection(),
                      // Daily Analysis
                      _buildDailyAnalysisSection(),
                      // Scroll Distance
                      _buildScrollDistanceSection(),
                      // Limits and debts
                      _buildLimitsSection(),
                      // Life Battery (En altta)
                      _buildLifeBatterySection(),
                      const SizedBox(height: 100), // Bottom padding for nav bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_showFocusMenu)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showFocusMenu = false),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                ),
              ),
            ),
          _buildFocusMenuOverlay(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildFocusMenuOverlay() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      bottom: _showFocusMenu ? 20 : -300,
      left: 0,
      right: 0,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FocusMenuButton(
              label: 'Odak Modu',
              icon: Icons.donut_large_rounded,
              color: AppColors.iosBlue,
              onTap: () {
                setState(() => _showFocusMenu = false);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const FocusModeScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _FocusMenuButton(
              label: 'Detoks Modu',
              icon: Icons.spa_rounded,
              color: AppColors.primary,
              onTap: () {
                setState(() => _showFocusMenu = false);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DetoxScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _FocusMenuButton(
              label: 'Pomodoro',
              icon: Icons.timer_rounded,
              color: const Color(0xFFFF5252),
              onTap: () {
                setState(() => _showFocusMenu = false);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PomodoroScreen()),
                );
              },
            ),
            const SizedBox(height: 40), // Spacing for bottom bar
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: AppColors.gray100.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kullanım Özeti',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Tab selector
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _buildTab('Günlük', 0),
                    _buildTab('Haftalık', 1),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLifeBatterySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _lifeBatteryPercentage > 0.2 
                            ? Icons.battery_charging_full_rounded 
                            : Icons.battery_alert_rounded, 
                        color: _lifeBatteryPercentage > 0.2 ? AppColors.success : AppColors.error, 
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yaşam Pili',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          _isRoutineSet ? 'Uyku & İş dışı zaman' : 'Rutin ayarlanmadı',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KALAN',
                      style: AppTextStyles.overline.copyWith(color: AppColors.textTertiary, fontSize: 10),
                    ),
                    Text(
                      '${(_lifeBatteryPercentage * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _lifeBatteryPercentage > 0.2 ? AppColors.textPrimary : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Battery bar
            if (!_isRoutineSet)
               SecondaryButton(
                 text: 'Rutini Ayarla',
                 onPressed: () async {
                   await Navigator.of(context).push(
                     MaterialPageRoute(builder: (context) => const SettingsScreen()),
                   );
                   _loadLifeBatteryData();
                 },
               )
            else
              Container(
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Percentage bar
                    FractionallySizedBox(
                      widthFactor: _lifeBatteryPercentage,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _lifeBatteryPercentage > 0.2 ? AppColors.success : AppColors.error, 
                              (_lifeBatteryPercentage > 0.2 ? AppColors.success : AppColors.error).withOpacity(0.8)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (_lifeBatteryPercentage > 0.2 ? AppColors.success : AppColors.error).withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Separators
                    Row(
                      children: List.generate(3, (index) => Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            if (_isRoutineSet)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                        children: [
                          const TextSpan(text: 'Serbest zamanının '),
                          TextSpan(
                            text: "%${((1.0 - _lifeBatteryPercentage) * 100).toStringAsFixed(0)}'ini", 
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)
                          ),
                          const TextSpan(text: ' telefona harcadın.\n'),
                          if (_lifeBatteryPercentage < 0.2)
                            TextSpan(
                              text: 'Dikkat: Gün bitmeden enerjin tükenebilir!',
                              style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalUsageSection() {
    final totalUsage = _currentUsage;
    final overLimit = totalUsage - HomeData.dailyLimit;
    final isOverLimit = overLimit.inMinutes > 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label
          Text(
            'BUGÜN TOPLAM',
            style: AppTextStyles.overline.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // Time display
          Text(
            AppUsageData.formatDuration(totalUsage),
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              letterSpacing: -3,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Over limit warning
          if (isOverLimit)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.error.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_rounded,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Günlük Limit Aşıldı (${AppUsageData.formatDuration(overLimit)})',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: _isLoading 
          ? const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()))
          : Column(
              children: [
                WeeklyChart(
                  data: _weeklyData,
                  onDaySelected: (index) {
                    _loadAppsForDay(index);
                    setState(() {
                      _selectedTabIndex = 0; // Günlük görünüme geç
                    });
                  },
                ),
                if (_selectedTabIndex == 1) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 24, bottom: 8),
                    child: Divider(height: 1),
                  ),
                  FutureBuilder<List<double>>(
                    future: HistoryService.getLast30DaysTotals(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('30 Günlük Hafıza', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textTertiary)),
                          ),
                          MonthlyChart(data: snapshot.data!),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
      ),
    );
  }

  Widget _buildDailyAnalysisSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _selectedTabIndex == 0 
          ? _calculateDailyAnalysis() 
          : HistoryService.getWeeklyAnalysis(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final analysis = snapshot.data!;
        
        if (_selectedTabIndex == 1) {
          // Weekly Analysis View
          final change = analysis['change'] as double;
          final thisWeekMs = analysis['thisWeekMs'] as int;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Text(
                  'Haftalık Analiz',
                  style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                _AnalysisCard(
                  icon: Icons.history_rounded,
                  iconBgColor: Colors.white,
                  iconColor: Colors.black,
                  title: 'HAFTALIK ÖZET',
                  description: 'Bu hafta geçen haftaya göre',
                  highlight: change >= 0 
                      ? '%${change.abs().toStringAsFixed(0)} daha fazla'
                      : '%${change.abs().toStringAsFixed(0)} daha az',
                  highlightColor: change >= 0 ? AppColors.error : AppColors.success,
                  suffix: 'aktif oldunuz.',
                  backgroundIcon: change >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                ),
              ],
            ),
          );
        }

        final todayTotal = analysis['todayTotal'] as Duration;
        final yesterdayTotal = analysis['yesterdayTotal'] as Duration;
        final generalChange = analysis['generalChange'] as double;
        final topApps = analysis['topApps'] as List<Map<String, dynamic>>;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              // Section header
              Row(
                children: [
                  Text(
                    'Günlük Analiz',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'İÇGÖRÜ',
                      style: AppTextStyles.overline.copyWith(
                        color: const Color(0xFF7C3AED),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // General analysis card
              _AnalysisCard(
                icon: Icons.insights_rounded,
                iconBgColor: Colors.white,
                iconColor: Colors.black,
                title: 'GENEL DURUM',
                description: 'Bugün dünden',
                highlight: generalChange >= 0 
                    ? '%${generalChange.abs().toStringAsFixed(0)} daha fazla'
                    : '%${generalChange.abs().toStringAsFixed(0)} daha az',
                highlightColor: generalChange >= 0 ? AppColors.error : AppColors.success,
                suffix: 'telefon kullandınız.',
                backgroundIcon: generalChange >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              ),
              // Top apps analysis
              ...topApps.take(2).map((app) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _AnalysisCard(
                  icon: null,
                  customIcon: app['iconBytes'] != null 
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(app['iconBytes'], width: 24, height: 24, fit: BoxFit.cover),
                        )
                      : Text(
                          (app['appName'] as String).isNotEmpty 
                              ? (app['appName'] as String)[0].toUpperCase() 
                              : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                  iconBgColor: AppColors.primary,
                  iconColor: Colors.white,
                  title: (app['appName'] as String).toUpperCase(),
                  description: 'Bugün dünden',
                  highlight: (app['change'] as double) >= 0 
                      ? '%${(app['change'] as double).abs().toStringAsFixed(0)} daha fazla'
                      : '%${(app['change'] as double).abs().toStringAsFixed(0)} daha az',
                  highlightColor: (app['change'] as double) >= 0 ? AppColors.error : AppColors.success,
                  suffix: 'vakit harcadınız.',
                ),
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _calculateDailyAnalysis() async {
    // Bugün ve dün için verileri al
    final todayApps = await UsageService.getAppListForDay(0, withAppInfo: true);
    final yesterdayApps = await UsageService.getAppListForDay(1);
    
    // Toplam kullanım
    Duration todayTotal = Duration.zero;
    Duration yesterdayTotal = Duration.zero;
    
    for (var app in todayApps) {
      todayTotal += app.usage;
    }
    for (var app in yesterdayApps) {
      yesterdayTotal += app.usage;
    }
    
    // Yüzde değişim
    double generalChange = 0;
    if (yesterdayTotal.inMinutes > 0) {
      generalChange = ((todayTotal.inMinutes - yesterdayTotal.inMinutes) / yesterdayTotal.inMinutes) * 100;
    }
    
    // Her uygulama için değişim hesapla
    final yesterdayMap = <String, Duration>{};
    for (var app in yesterdayApps) {
      yesterdayMap[app.packageName] = app.usage;
    }
    
    List<Map<String, dynamic>> topApps = [];
    for (var app in todayApps.take(5)) {
      final yesterdayUsage = yesterdayMap[app.packageName] ?? Duration.zero;
      double change = 0;
      if (yesterdayUsage.inMinutes > 0) {
        change = ((app.usage.inMinutes - yesterdayUsage.inMinutes) / yesterdayUsage.inMinutes) * 100;
      } else if (app.usage.inMinutes > 0) {
        change = 100; // Dün kullanılmamış, bugün kullanılıyor
      }
      
      // Uygulama adını düzgün al (eğer sistemden gelen isim 'android' ise bizim fonksiyona zorla)
      String? systemName = app.appName;
      String displayName;
      
      if (systemName == null || systemName.toLowerCase() == 'android') {
        displayName = _extractAppName(app.packageName);
      } else {
        displayName = systemName;
      }
      
      topApps.add({
        'packageName': app.packageName,
        'appName': displayName,
        'iconBytes': app.iconBytes,
        'todayUsage': app.usage,
        'yesterdayUsage': yesterdayUsage,
        'change': change,
      });
    }
    
    return {
      'todayTotal': todayTotal,
      'yesterdayTotal': yesterdayTotal,
      'generalChange': generalChange,
      'topApps': topApps,
    };
  }

  /// Paket adından okunabilir uygulama adı çıkar
  String _extractAppName(String packageName) {
    // Bilinen paketler için özel isimler
    final knownApps = {
      'com.google.android.youtube': 'YouTube',
      'com.google.android.gm': 'Gmail',
      'com.google.android.apps.photos': 'Google Fotoğraflar',
      'com.google.android.apps.maps': 'Google Haritalar',
      'com.google.android.apps.docs': 'Google Drive',
      'com.google.android.calendar': 'Google Takvim',
      'com.google.android.keep': 'Google Keep',
      'com.google.android.apps.messaging': 'Mesajlar',
      'com.google.android.dialer': 'Telefon',
      'com.google.android.contacts': 'Kişiler',
      'com.android.chrome': 'Chrome',
      'com.android.vending': 'Play Store',
      'com.whatsapp': 'WhatsApp',
      'com.instagram.android': 'Instagram',
      'com.twitter.android': 'Twitter',
      'com.facebook.katana': 'Facebook',
      'com.facebook.orca': 'Messenger',
      'org.telegram.messenger': 'Telegram',
      'com.spotify.music': 'Spotify',
      'com.netflix.mediaclient': 'Netflix',
      'com.trendyol.trendyolapp': 'Trendyol',
      'com.hepsiburada': 'Hepsiburada',
      'com.getir': 'Getir',
      'com.yemeksepeti.android': 'Yemeksepeti',
    };
    
    if (knownApps.containsKey(packageName)) {
      return knownApps[packageName]!;
    }
    
    // Paket adından en anlamlı kısmı bul
    final parts = packageName.split('.');
    final skipWords = ['com', 'org', 'net', 'android', 'app', 'apps', 'mobile', 'client', 'lite'];
    
    // Sondan başa en anlamlı kelimeyi bul
    for (int i = parts.length - 1; i >= 0; i--) {
      final part = parts[i].toLowerCase();
      if (!skipWords.contains(part) && part.length > 2) {
        // İlk harfi büyük yap
        return parts[i][0].toUpperCase() + parts[i].substring(1);
      }
    }
    
    // Hiçbir şey bulunamazsa son kısmı döndür
    return parts.last[0].toUpperCase() + parts.last.substring(1);
  }

  Widget _buildScrollDistanceSection() {
    return FutureBuilder<Map<String, ScrollDistanceResult>>(
      future: _calculateScrollData(),
      builder: (context, snapshot) {
        final todayData = snapshot.data?['today'];
        final yesterdayData = snapshot.data?['yesterday'];
        
        final totalMeters = todayData?.totalMeters ?? 0;
        final comparisonText = todayData?.comparisonText ?? '0 metre';
        final comparisonEmoji = todayData?.comparisonEmoji ?? '📏';
        
        // Dün ile karşılaştırma
        double changePercent = 0;
        if (yesterdayData != null && yesterdayData.totalMeters > 0) {
          changePercent = ((totalMeters - yesterdayData.totalMeters) / yesterdayData.totalMeters) * 100;
        }
        
        // Ortalama hesapla (basit: dünün verisi)
        final avgMeters = yesterdayData?.totalMeters ?? totalMeters;
        final avgDisplay = avgMeters >= 1000 
            ? '${(avgMeters / 1000).toStringAsFixed(1)} km'
            : '${avgMeters.toStringAsFixed(0)} m';
        
        // Progress bar için oran
        double progressRatio = avgMeters > 0 ? (totalMeters / avgMeters).clamp(0.0, 1.5) / 1.5 : 0.5;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Kaydırma Mesafesi',
                    style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.iosBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'TAHMİNİ',
                      style: AppTextStyles.overline.copyWith(color: AppColors.iosBlue, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BUGÜN KAT EDİLEN',
                              style: AppTextStyles.overline.copyWith(color: AppColors.textTertiary, letterSpacing: 1),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  totalMeters >= 1000 
                                      ? (totalMeters / 1000).toStringAsFixed(1)
                                      : totalMeters.toStringAsFixed(0),
                                  style: AppTextStyles.displayLarge.copyWith(fontSize: 48, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  totalMeters >= 1000 ? 'km' : 'metre',
                                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.iosBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(Icons.swipe_up_rounded, color: AppColors.iosBlue, size: 30),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Comparison card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
                            ),
                            child: Center(child: Text(comparisonEmoji, style: const TextStyle(fontSize: 24))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  comparisonText,
                                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                    children: [
                                      const TextSpan(text: 'Başparmağın bugün tam '),
                                      TextSpan(text: comparisonText, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                                      const TextSpan(text: ' yüksekliğinde yol kat etti.'),
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
                    // Average bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progressRatio,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.iosBlue,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Dün: $avgDisplay',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        children: [
                          const TextSpan(text: 'Düne göre '),
                          TextSpan(
                            text: changePercent >= 0 
                                ? '%${changePercent.abs().toStringAsFixed(0)} daha fazla'
                                : '%${changePercent.abs().toStringAsFixed(0)} daha az',
                            style: TextStyle(
                              color: changePercent >= 0 ? AppColors.error : AppColors.success, 
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: ' kaydırdın.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, ScrollDistanceResult>> _calculateScrollData() async {
    final today = await UsageService.getEstimatedScrollDistance(0);
    final yesterday = await UsageService.getEstimatedScrollDistance(1);
    return {'today': today, 'yesterday': yesterday};
  }

  Widget _buildLimitsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          // Section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Limitler ve Borçlar',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              // YÖNET button - Glass style small
              _GlassSmallButton(
                text: 'YÖNET',
                icon: Icons.tune_rounded,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddLimitScreen()),
                  );
                  if (result == true) {
                    _loadDynamicLimits();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // App limit cards
          if (_dynamicLimits.isEmpty)
             Center(
               child: Padding(
                 padding: const EdgeInsets.symmetric(vertical: 20),
                 child: Text('Henüz limit eklemediniz.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary)),
               ),
             ),
          ..._dynamicLimits.map((app) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppLimitCard(
              data: app,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AppDetailScreen(
                      appName: app.iconType, // limit.packageName iconType'a atanmıştı
                      iconType: app.iconType,
                    ),
                  ),
                );
                _loadDynamicLimits();
              },
            ),
          )),
          // Add new limit button - Glass style
          const SizedBox(height: 8),
          SecondaryButton(
            text: 'Yeni Limit Ekle',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddLimitScreen()),
              );
              if (result == true) {
                _loadDynamicLimits();
              }
            },
          ),
        ],
      ),
    );
  }  Widget _buildChainSection() {
    return FutureBuilder<Map<String, dynamic>>(
      future: HistoryService.getStreakData(),
      builder: (context, snapshot) {
        final streak = snapshot.data?['streak'] ?? 0;
        final goalHours = snapshot.data?['goalHours'] ?? 4;
        final now = DateTime.now();
        final monthName = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'][now.month - 1];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Zinciri Kırma',
                    style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'TAKVİM',
                      style: AppTextStyles.overline.copyWith(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$monthName ${now.year}',
                              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text(
                                  'Hedef: Günde $goalHours saatin altı',
                                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'SERİ',
                              style: AppTextStyles.overline.copyWith(color: AppColors.textTertiary, fontSize: 10),
                            ),
                            Row(
                              children: [
                                Text(
                                  '$streak',
                                  style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(width: 4),
                                Text(streak > 0 ? '🔥' : '❄️', style: const TextStyle(fontSize: 20)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Calendar header
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _CalendarDayHeader(text: 'Pzt'),
                        _CalendarDayHeader(text: 'Sal'),
                        _CalendarDayHeader(text: 'Çar'),
                        _CalendarDayHeader(text: 'Per'),
                        _CalendarDayHeader(text: 'Cum'),
                        _CalendarDayHeader(text: 'Cmt'),
                        _CalendarDayHeader(text: 'Paz'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(color: AppColors.gray100, height: 1),
                    const SizedBox(height: 16),
                    // Calendar grid
                    FutureBuilder<Map<String, int>>(
                      future: HistoryService.getCalendarData(),
                      builder: (context, calSnapshot) {
                        final calendarData = calSnapshot.data ?? {};
                        
                        // Ayın başlangıcını ve haftanın gününü bul
                        final firstDayOfMonth = DateTime(now.year, now.month, 1);
                        final startPadding = firstDayOfMonth.weekday - 1; // 0=Mon, 1=Tue...
                        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 7,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 8,
                          children: [
                            // Ay evvelindeki boşluklar
                            ...List.generate(startPadding, (index) => const SizedBox()),
                            // Ayın günleri
                            ...List.generate(daysInMonth, (index) {
                              final day = index + 1;
                              final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
                              
                              DayStatus status = DayStatus.future;
                              if (day < now.day) {
                                final result = calendarData[dateStr];
                                if (result == 1) status = DayStatus.completed;
                                else if (result == 2) status = DayStatus.missed;
                                else status = DayStatus.future;
                              } else if (day == now.day) {
                                status = DayStatus.current;
                              }

                              return _CalendarDay(status: status, day: day.toString());
                            }),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(streak > 0 ? Icons.emoji_events_rounded : Icons.info_outline_rounded, color: AppColors.success, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
                                children: [
                                  TextSpan(text: streak > 0 ? 'Harika gidiyorsun! ' : 'Yeni bir başlangıç yap! '),
                                  TextSpan(text: 'Son $streak gündür', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                                  const TextSpan(text: ' hedefini tutturuyorsun. Seriyi bozmamak için bugün de dikkatli ol.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDailyAppListSection() {
    if (_selectedTabIndex == 1) {
      return FutureBuilder<Map<String, int>>(
        future: HistoryService.getWeeklyAppAggregation(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          
          final apps = snapshot.data!;
          final sortedPkgs = apps.keys.toList()..sort((a, b) => apps[b]!.compareTo(apps[a]!));
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Haftalık Uygulama Listesi',
                      style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${sortedPkgs.length} Uygulama',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...sortedPkgs.take(15).map((pkg) => _AppUsageItem(
                  packageName: pkg,
                  usage: Duration(milliseconds: apps[pkg]!),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AppDetailScreen(
                          appName: pkg,
                          iconType: 'default',
                        ),
                      ),
                    );
                    _loadDynamicLimits();
                  },
                )),
              ],
            ),
          );
        },
      );
    }

    final dayName = _weeklyData.isNotEmpty && _selectedDayIndex < _weeklyData.length 
        ? _weeklyData[_selectedDayIndex].dayLabel 
        : "";
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$dayName Günü Kullanımı',
                style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                '${_selectedDayApps.length} Uygulama',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedDayApps.isEmpty && !_isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('Bu gün için veri bulunamadı.', style: AppTextStyles.bodyMedium),
              ),
            ),
          ..._selectedDayApps.take(15).map((app) => _AppUsageItem(
            packageName: app.packageName,
            usage: app.usage,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AppDetailScreen(
                    appName: app.packageName,
                    iconType: 'default',
                  ),
                ),
              );
              _loadDynamicLimits();
            },
          )),
          if (_selectedDayApps.length > 15)
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text('Tümünü Gör', style: TextStyle(color: AppColors.iosBlue)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small glass button for inline use
class _GlassSmallButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _GlassSmallButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_GlassSmallButton> createState() => _GlassSmallButtonState();
}

class _GlassSmallButtonState extends State<_GlassSmallButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _isPressed ? const Color(0xFFE0E0E0) : const Color(0xFFF0F0F0),
                _isPressed ? const Color(0xFFD0D0D0) : const Color(0xFFE2E2E2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              width: 1,
              color: Colors.white.withOpacity(0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.text,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Analysis insight card widget
class _AnalysisCard extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final Color? iconBgColor;
  final Gradient? iconGradient;
  final Color iconColor;
  final String title;
  final String description;
  final String highlight;
  final Color highlightColor;
  final String suffix;
  final IconData? backgroundIcon;

  const _AnalysisCard({
    this.icon,
    this.customIcon,
    this.iconBgColor,
    this.iconGradient,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.highlight,
    required this.highlightColor,
    required this.suffix,
    this.backgroundIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gray100,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Background icon
          if (backgroundIcon != null)
            Positioned(
              right: -16,
              bottom: -16,
              child: Icon(
                backgroundIcon,
                size: 64,
                color: AppColors.gray200.withOpacity(0.5),
              ),
            ),
          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  gradient: iconGradient,
                  borderRadius: BorderRadius.circular(12),
                  border: iconBgColor == Colors.white 
                      ? Border.all(color: AppColors.gray100, width: 1)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: customIcon ?? Icon(icon, color: iconColor, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(text: '$description '),
                          TextSpan(
                            text: highlight,
                            style: TextStyle(color: highlightColor),
                          ),
                          TextSpan(text: ' $suffix'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum DayStatus { completed, missed, current, future }

class _CalendarDayHeader extends StatelessWidget {
  final String text;
  const _CalendarDayHeader({required this.text});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTextStyles.overline.copyWith(color: AppColors.textTertiary, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final DayStatus status;
  final String? day;
  
  const _CalendarDay({required this.status, this.day});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case DayStatus.completed:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        );
      case DayStatus.missed:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.error.withOpacity(0.5)),
          ),
          child: Center(
            child: Text(
              day ?? '',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.error, 
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      case DayStatus.current:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Center(
            child: Text(
              day ?? '',
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        );
      case DayStatus.future:
        return Center(
          child: Text(
            day ?? '',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.gray300, fontWeight: FontWeight.w600),
          ),
        );
    }
  }
}

class _FocusMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FocusMenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppUsageItem extends StatelessWidget {
  final String packageName;
  final Duration usage;
  final VoidCallback onTap;

  const _AppUsageItem({
    required this.packageName,
    required this.usage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Popüler uygulamalar için manuel eşleştirme ve temiz isim çıkarma
    String displayName = packageName;
    
    final Map<String, String> commonApps = {
      'com.instagram.android': 'Instagram',
      'com.google.android.youtube': 'YouTube',
      'com.twitter.android': 'Twitter (X)',
      'com.whatsapp': 'WhatsApp',
      'com.facebook.katana': 'Facebook',
      'com.facebook.orca': 'Messenger',
      'com.google.android.apps.messaging': 'Mesajlar',
      'com.android.chrome': 'Chrome',
      'com.google.android.googlequicksearchbox': 'Google',
      'com.spotify.music': 'Spotify',
      'com.netflix.mediaclient': 'Netflix',
      'com.zhiliaoapp.musically': 'TikTok',
      'com.discord': 'Discord',
      'com.microsoft.teams': 'Teams',
      'com.slack': 'Slack',
    };

    if (commonApps.containsKey(packageName)) {
      displayName = commonApps[packageName]!;
    } else {
      // Paket isminden tahmini isim çıkar (com.example.app -> Example)
      List<String> parts = packageName.split('.');
      if (parts.length >= 2) {
        // Genellikle ortadaki kısım (com.spotify.music -> spotify) veya son kısım (com.whatsapp -> whatsapp) anlamlıdır
        String candidate = parts.length > 2 ? parts[parts.length - 2] : parts.last;
        
        // 'android', 'apps', 'google' gibi gereksiz kelimeleri atla
        if ((candidate == 'android' || candidate == 'apps' || candidate == 'google') && parts.length > 2) {
          candidate = parts[parts.length - 1];
        }
        
        displayName = candidate[0].toUpperCase() + candidate.substring(1);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.iosBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.apps_rounded, color: AppColors.iosBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    packageName,
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              AppUsageData.formatDuration(usage),
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: AppColors.gray300, size: 20),
          ],
        ),
      ),
    );
  }
}
