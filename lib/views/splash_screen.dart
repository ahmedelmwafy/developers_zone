import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'waiting_approval_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  void _checkStatus() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    final authController = Provider.of<AuthController>(context, listen: false);
    
    // Show Splash Ad (Dialog style as requested)
    _showSplashAd().then((_) async {
      if (!mounted) return;
      if (authController.currentUser != null) {
        if (authController.currentUser!.isApproved) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WaitingApprovalPage()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  Future<void> _showSplashAd() async {
    final adminController = Provider.of<AdminController>(context, listen: false);
    final ads = await adminController.getAds(type: 'splash').first;
    
    if (ads.isEmpty || !mounted) return;
    
    final ad = ads.first;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Handle link navigation
                Navigator.pop(context);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(ad.imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            Text(ad.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 150, height: 150),
            const SizedBox(height: 20),
            const Text(
              'Developers Zone',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
