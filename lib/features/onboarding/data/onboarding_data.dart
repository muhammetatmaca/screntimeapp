/// Onboarding data model
class OnboardingItem {
  final String title;
  final String subtitle;
  final String imagePath;
  final OnboardingCardData? cardData;

  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.cardData,
  });
}

/// Card data for specific onboarding screens
class OnboardingCardData {
  final String? weekLabel;
  final String? percentageChange;
  final String? costLabel;
  final String? costValue;
  final List<double>? chartValues;
  final List<OnboardingFeatureItem>? features;

  const OnboardingCardData({
    this.weekLabel,
    this.percentageChange,
    this.costLabel,
    this.costValue,
    this.chartValues,
    this.features,
  });
}

/// Feature item for the third onboarding screen
class OnboardingFeatureItem {
  final String icon;
  final String title;
  final String? value;
  final double? progress;
  final List<bool>? chainDots;
  final int color; // Color as hex int

  const OnboardingFeatureItem({
    required this.icon,
    required this.title,
    this.value,
    this.progress,
    this.chainDots,
    required this.color,
  });
}

/// Static onboarding data based on Figma designs
class OnboardingData {
  static const List<OnboardingItem> items = [
    // Screen 1: Ekran Süresi Faturası
    OnboardingItem(
      title: 'Zamanın Gerçek Bedeli',
      subtitle:
          'Telefonunuzda harcadığınız süreyi nakite çevirip gösteriyoruz. Farkındalık kazanın, tasarruf edin.',
      imagePath: 'assets/images/onboarding_1.png',
      cardData: OnboardingCardData(
        weekLabel: 'Bu Hafta',
        percentageChange: '+24%',
        costLabel: 'Toplam Dakika',
        costValue: '1450',
        chartValues: [0.4, 0.7, 1.0, 0.6],
      ),
    ),

    // Screen 2: Ekran Süresi Kontrolü
    OnboardingItem(
      title: 'Zamanını Yönet,\nHayatını Yaşa',
      subtitle:
          'Uygulama ve içerik bazında ekran süresi limitleri belirle, dijital alışkanlıklarını kontrol altına al.',
      imagePath: 'assets/images/onboarding_2.png',
    ),

    // Screen 3: Farkındalık ve Motivasyon
    OnboardingItem(
      title: 'Alışkanlıklarını Keşfet, Kendine Yatırım Yap',
      subtitle:
          "Günlük 'kaydırma mesafeni' gör, 'Yaşam Pili'ni takip et ve 'Zinciri Kırma' takvimiyle hedeflerine ulaş.",
      imagePath: 'assets/images/onboarding_3.png',
      cardData: OnboardingCardData(
        features: [
          OnboardingFeatureItem(
            icon: 'battery_charging_full',
            title: 'Yaşam Pili',
            progress: 0.75,
            color: 0xFF13EC5B, // Primary green
          ),
          OnboardingFeatureItem(
            icon: 'straighten',
            title: 'Kaydırma Mesafesi',
            value: '124 metre',
            color: 0xFF3B82F6, // Blue
          ),
          OnboardingFeatureItem(
            icon: 'calendar_month',
            title: 'Zinciri Kırma',
            chainDots: [true, true, true, false],
            color: 0xFFF97316, // Orange
          ),
        ],
      ),
    ),
  ];
}
