import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../providers/app_provider.dart';
import '../models/ad_model.dart';
import 'profile_page.dart';
import 'network_page.dart';
import 'feed_page.dart';
import 'search_screen.dart';
import 'components/notification_badge.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkProfileCompleteness());
  }

  void _checkProfileCompleteness() {
    final auth = Provider.of<AuthController>(context, listen: false);
    final user = auth.currentUser;
    if (user != null && !user.isVerified) {
      final isComplete = user.name.isNotEmpty &&
          user.position.isNotEmpty &&
          user.bio.isNotEmpty &&
          user.city.isNotEmpty &&
          user.profileImage.isNotEmpty;

      if (!isComplete) {
        _showCompleteProfileDialog();
      }
    }
  }

  void _showCompleteProfileDialog() {
    final locale = AppLocalization.of(context)!;
    final appProps = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(locale.translate('profile_incomplete'),
            style: GoogleFonts.spaceGrotesk(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded,
                  size: 48, color: Color(0xFF00E5FF)),
            ),
            const SizedBox(height: 16),
            Text(locale.translate('complete_to_verify'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.6))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.translate('cancel'),
                style: GoogleFonts.spaceGrotesk(color: Colors.white30)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              appProps.setTabIndex(3); // Navigate to Profile
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(locale.translate('complete_profile'),
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final appProps = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        titleSpacing: 24,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
              ),
              child: const Icon(Icons.terminal_rounded,
                  color: Color(0xFF00E5FF), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              locale.translate('REPOSITORY'),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          const Center(child: NotificationBadge()),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: appProps.currentTabIndex,
        children: const [
          FeedPage(),
          NetworkPage(),
          SearchScreen(),
          ProfilePage(),
        ],
      ),
      bottomNavigationBar: _DigitalBottomNav(
        currentIndex: appProps.currentTabIndex,
        onTap: (i) => appProps.setTabIndex(i),
      ),
    );
  }
}

class _DigitalBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _DigitalBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.dns_rounded, 'label': 'FEED'},
      {'icon': Icons.people_alt_rounded, 'label': 'NETWORK'},
      {'icon': Icons.search_rounded, 'label': 'SEARCH'},
      {'icon': Icons.account_circle_rounded, 'label': 'PROFILE'},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF80DEEA), Color(0xFF00E5FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: isSelected
                              ? Colors.black
                              : Colors.white.withOpacity(0.2),
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.spaceGrotesk(
                            color: isSelected
                                ? Colors.black
                                : Colors.white.withOpacity(0.3),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class HomeAdsSection extends StatelessWidget {
  const HomeAdsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Provider.of<AdminController>(context);

    return StreamBuilder<AdSettingsModel>(
      stream: adminController.getAdSettings(),
      builder: (context, settingsSnapshot) {
        if (!settingsSnapshot.hasData ||
            !settingsSnapshot.data!.homeCustomAdActive) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<List<AdModel>>(
          stream: adminController.getAds(type: 'home'),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }
            final ads = snapshot.data!;

            return Container(
              height: 90,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: PageView.builder(
                itemCount: ads.length,
                itemBuilder: (context, index) {
                  final ad = ads[index];
                  return GestureDetector(
                    onTap: () async {
                      if (ad.targetUrl != null) {
                        final url = Uri.parse(ad.targetUrl!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                            image: NetworkImage(ad.imageUrl),
                            fit: BoxFit.cover),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF00E5FF).withOpacity(0.1),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          ad.title,
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
