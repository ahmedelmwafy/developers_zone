import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../models/ad_model.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'waiting_approval_page.dart';
import 'incomplete_profile_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  String _statusKey = 'initializing_core';
  double _percent = 0.0;
  AdModel? _featuredAd;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _progressAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _progressController.addListener(() {
      setState(() {
        _percent = _progressAnimation.value;
        if (_percent > 0.8) {
          _statusKey = 'syncing_repos';
        } else if (_percent > 0.5) {
          _statusKey = 'verifying_nodal_protocols';
        } else if (_percent > 0.3) {
          _statusKey = 'establishing_secure_session';
        }
      });
    });

    _progressController.forward();
    _loadData();
  }

  void _loadData() async {
    final adminController = Provider.of<AdminController>(context, listen: false);
    
    // Check if splash ads are enabled
    final settings = await adminController.getAdSettings().first;
    if (settings.splashCustomAdActive) {
      final adStream = adminController.getAds(type: 'splash');
      final ads = await adStream.first;
      if (ads.isNotEmpty) {
        setState(() => _featuredAd = ads.first);
      }
    }

    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final authController = Provider.of<AuthController>(context, listen: false);
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Wait for auth initialization to complete
    int retries = 0;
    while (!authController.isInitialized && retries < 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      retries++;
    }

    if (authController.currentUser != null) {
      if (authController.currentUser!.isApproved) {
        if (!authController.isProfileComplete && !appProvider.hasSeenProfilePrompt) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const IncompleteProfilePage()));
        } else {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WaitingApprovalPage()));
      }
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          const Positioned.fill(child: _DigitalGridPainter()),
          _buildBackglow(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                const Spacer(flex: 3),
                _buildLogoHeader(),
                const SizedBox(height: 40),
                _buildProgressSection(),
                const SizedBox(height: 48),
                if (_featuredAd != null) _buildPromotedCard(_featuredAd!),
                const Spacer(flex: 2),
                _buildFooter(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackglow() {
    return Positioned(
      top: -100,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.05),
                blurRadius: 150,
                spreadRadius: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoHeader() {
    final locale = AppLocalization.of(context)!;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(Icons.terminal_rounded,
                    color: Color(0xFF00E5FF), size: 36),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00E5FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0xFF00E5FF), blurRadius: 4)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          locale.translate('DEVELOPERS_ZONE').split(' ')[0],
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 44,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        Text(
          locale.translate('DEVELOPERS_ZONE').split(' ').last,
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFF00E5FF),
            fontWeight: FontWeight.w900,
            fontSize: 44,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          locale.translate('architecting_future'),
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withOpacity(0.3),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      children: [
        Container(
          height: 2,
          width: double.infinity,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _percent,
            child: Container(color: const Color(0xFF00E5FF)),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalization.of(context)!.translate(_statusKey),
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFF00E5FF).withOpacity(0.8),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              '${(_percent * 100).toInt()}%',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPromotedCard(AdModel ad) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 7,
              child: Image.network(
                ad.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white.withOpacity(0.05),
                  child: const Icon(Icons.cloud_queue_rounded,
                      color: Colors.white24, size: 40),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2979FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  AppLocalization.of(context)!.translate('promoted'),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                ad.title.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ad.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              if (ad.targetUrl != null) {
                final url = Uri.parse(ad.targetUrl!);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                AppLocalization.of(context)!.translate('deploy_now'),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.terminal_rounded, size: 14, color: Colors.white.withOpacity(0.2)),
        const SizedBox(width: 8),
        Text(
          AppLocalization.of(context)!.translate('stable_version'),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withOpacity(0.2),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 24),
        Icon(Icons.shield_rounded, size: 14, color: Colors.white.withOpacity(0.2)),
        const SizedBox(width: 8),
        Text(
          AppLocalization.of(context)!.translate('e2e_encryption'),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withOpacity(0.2),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _DigitalGridPainter extends StatelessWidget {
  const _DigitalGridPainter();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawLine(Offset(i, j - 4), Offset(i, j + 4), paint);
        canvas.drawLine(Offset(i - 4, j), Offset(i + 4, j), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
