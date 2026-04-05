import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../views/login_screen.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      titleKey: 'ONBOARDING_TITLE_1',
      subtitleKey: 'ONBOARDING_SUB_1',
      icon: Icons.terminal_rounded,
    ),
    OnboardingItem(
      titleKey: 'ONBOARDING_TITLE_2',
      subtitleKey: 'ONBOARDING_SUB_2',
      icon: Icons.sync_rounded,
    ),
    OnboardingItem(
      titleKey: 'ONBOARDING_TITLE_3',
      subtitleKey: 'ONBOARDING_SUB_3',
      icon: Icons.verified_user_rounded,
      isLast: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          const Positioned.fill(child: _DigitalGridPainter()),
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildVisual(item.icon),
                          const SizedBox(height: 64),
                          Text(
                            AppLocalization.of(context)!.translate(item.titleKey),
                            textAlign: TextAlign.center,
                            style: AppLocalization.digitalFont(
                              context,
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppLocalization.of(context)!.translate(item.subtitleKey),
                            textAlign: TextAlign.center,
                            style: AppLocalization.digitalFont(
                              context,
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _buildBottomBar(),
              const SizedBox(height: 48),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TextButton(
              onPressed: _finishOnboarding,
              child: Text(
                AppLocalization.of(context)!.translate('all_caps').toUpperCase(), // SKIP fallback or better key
                style: AppLocalization.digitalFont(
                  context,
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisual(IconData icon) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.05),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 80,
          color: const Color(0xFF00E5FF),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentPage == _items.length - 1;
    final locale = AppLocalization.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _items.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color(0xFF00E5FF)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
          GestureDetector(
            onTap: isLast ? _finishOnboarding : _nextPage,
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isLast ? locale.translate('INITIALIZE_SESSION').toUpperCase() : locale.translate('CONFIRM_ACTION').toUpperCase(),
                  style: AppLocalization.digitalFont(
                    context,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _finishOnboarding() {
    Provider.of<AppProvider>(context, listen: false).setSeenOnboarding(true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

class OnboardingItem {
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final bool isLast;

  OnboardingItem({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    this.isLast = false,
  });
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
      ..color = Colors.white.withValues(alpha: 0.02)
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
