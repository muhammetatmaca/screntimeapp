import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'core/services/settings_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
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

  // Initialization complete, remove splash
  FlutterNativeSplash.remove();

  runApp(SpentApp(isSetupDone: isSetupDone));
}

class SpentApp extends StatelessWidget {
  final bool isSetupDone;
  
  const SpentApp({super.key, required this.isSetupDone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flow: Focus & Screen Time',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first; // Default to English
      },
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Start with light mode
      home: isSetupDone ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
