import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'core/services/settings_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Bildirim ve Arka Plan Servisini başlat
  await NotificationService.init();
  await BackgroundService.init();
  await BackgroundService.startUsageCheck();

  // Check if onboarding is done
  final bool isSetupDone = await SettingsService.isSetupDone();

  runApp(SpentApp(isSetupDone: isSetupDone));
}

class SpentApp extends StatelessWidget {
  final bool isSetupDone;
  
  const SpentApp({super.key, required this.isSetupDone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spent: Time & Focus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Start with light mode
      home: isSetupDone ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
