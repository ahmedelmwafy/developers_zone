import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'waiting_approval_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _particleController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    _logoScale = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut).drive(
      Tween<double>(begin: 0.3, end: 1.0),
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: const Interval(0.0, 0.5)).drive(
      Tween<double>(begin: 0.0, end: 1.0),
    );
    _textFade = CurvedAnimation(parent: _logoController, curve: const Interval(0.5, 1.0)).drive(
      Tween<double>(begin: 0.0, end: 1.0),
    );
    _textSlide = CurvedAnimation(parent: _logoController, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)).drive(
      Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero),
    );

    _logoController.forward();
    _checkStatus();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _checkStatus() async {
    // Minimum 2.5s to show the splash animation.
    // Then wait (up to 5s more) for Firebase to restore session.
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final authController = Provider.of<AuthController>(context, listen: false);

    // Poll until isInitialized, with a 5s safety timeout.
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!authController.isInitialized && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    _showSplashAd().then((_) async {
      if (!mounted) return;
      if (authController.currentUser != null) {
        if (authController.currentUser!.isApproved) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const WaitingApprovalPage()));
        }
      } else {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(ad.imageUrl, fit: BoxFit.cover),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(ad.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Animated background particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) => CustomPaint(
              painter: _ParticlePainter(_particleController.value),
              size: MediaQuery.of(context).size,
            ),
          ),
          // Glow backdrop
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 120, spreadRadius: 60)],
              ),
            ),
          ),
          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo with scale + fade animation
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 5),
                          BoxShadow(color: AppColors.accent.withValues(alpha: 0.2), blurRadius: 60, spreadRadius: 10),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.code, size: 60, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                // Animated text
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                          child: const Text(
                            'Developers Zone',
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Where code meets community',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                FadeTransition(
                  opacity: _textFade,
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final _particles = List.generate(20, (i) => _Particle(i));

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x = (p.x * size.width + progress * p.speedX * size.width) % size.width;
      final y = (p.y * size.height + progress * p.speedY * size.height) % size.height;
      final paint = Paint()
        ..color = (p.isAccent ? AppColors.accent : AppColors.primary).withValues(alpha: p.opacity * (0.5 + 0.5 * sin(progress * 2 * pi + p.phase)))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(x, y), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

class _Particle {
  final double x, y, speedX, speedY, opacity, radius, phase;
  final bool isAccent;
  _Particle(int seed)
      : x = (seed * 0.13 + 0.05) % 1.0,
        y = (seed * 0.17 + 0.03) % 1.0,
        speedX = (seed % 5 - 2) * 0.05,
        speedY = -(seed % 4 + 1) * 0.04,
        opacity = 0.2 + (seed % 5) * 0.08,
        radius = 1.5 + (seed % 4) * 1.0,
        phase = seed * 0.7,
        isAccent = seed % 3 == 0;
}
