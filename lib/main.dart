import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'providers/app_provider.dart';
import 'controllers/auth_controller.dart';
import 'controllers/post_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/admin_controller.dart';
import 'views/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.initialize();
  MobileAds.instance.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => PostController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => AdminController()),
      ],
      child: const DevelopersZoneApp(),
    ),
  );
}

class DevelopersZoneApp extends StatelessWidget {
  const DevelopersZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Developers Zone',
      theme: ThemeData(
        fontFamily: appProvider.locale.languageCode == 'ar' ? 'Tajawal' : 'Poppins',
        primarySwatch: Colors.deepPurple,
        primaryColor: const Color(0xFF673AB7),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0E17),
          elevation: 0,
        ),
      ),
      locale: appProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizationDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorKey: NotificationService.navigatorKey,
      home: const SplashScreen(),
    );
  }
}
