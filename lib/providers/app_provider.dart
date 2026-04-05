import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ad_model.dart';
import '../services/firestore_service.dart';
import 'dart:async';

class AppLocalization {
  final Locale locale;
  AppLocalization(this.locale);

  static AppLocalization? of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization);
  }

  late Map<String, String> _localizedStrings;

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('assets/translations/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  static bool isArabic(BuildContext context) =>
      of(context)?.locale.languageCode == 'ar';

  static TextStyle font({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) {
    // We'll use a hack to get the locale since we can't easily pass context everywhere
    // but the best way is to pass it. Since we are in the class, we'll assume the user
    // will call it with context or we'll provide a fallback.
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // Improved font getter that takes context
  static TextStyle digitalFont(
    BuildContext context, {
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
  }) {
    final isAr = isArabic(context);
    if (isAr) {
      return GoogleFonts.cairo(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight ?? FontWeight.w700,
        height: height,
      );
    }
    return GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalization> load(Locale locale) async {
    AppLocalization localizations = AppLocalization(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}

class AppProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;
  bool _hasSeenProfilePrompt = false;
  bool get hasSeenProfilePrompt => _hasSeenProfilePrompt;

  AppProvider() {
    _loadLocale();
  }

  void setSeenProfilePrompt(bool val) {
    _hasSeenProfilePrompt = val;
    notifyListeners();
  }

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  AdSettingsModel _adSettings = AdSettingsModel();
  AdSettingsModel get adSettings => _adSettings;
  StreamSubscription? _adSub;

  void initAdSettings() {
    _adSub?.cancel();
    _adSub = FirestoreService().streamAdSettings().listen((settings) {
      _adSettings = settings;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _adSub?.cancel();
    super.dispose();
  }

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('languageCode') ?? 'en';
    _locale = Locale(lang);
    notifyListeners();
  }

  void setLocale(Locale newLocale) async {
    _locale = newLocale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', newLocale.languageCode);
    notifyListeners();
  }
}
