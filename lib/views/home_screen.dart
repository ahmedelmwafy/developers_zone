import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../providers/app_provider.dart';
import '../models/ad_model.dart';
import 'profile_page.dart';
import 'chat_list_page.dart';
import 'feed_page.dart';
import 'search_screen.dart';
import 'components/notification_badge.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/banner_ad_widget.dart';
import 'settings_screen.dart';
import '../widgets/terminal_dialog.dart';

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
      builder: (context) => TerminalDialog(
        headerTag: 'GENESIS_PROTOCOL',
        title: locale.translate('profile_incomplete'),
        body: locale.translate('complete_to_verify'),
        confirmLabel: locale.translate('complete_profile'),
        cancelLabel: locale.translate('cancel'),
        onConfirm: () {
          Navigator.pop(context);
          appProps.setTabIndex(3); // Navigate to Profile
        },
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
                color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.terminal_rounded,
                  color: Color(0xFF00E5FF), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              locale.translate('REPOSITORY'),
              style: AppLocalization.digitalFont(
                context,
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          if (Provider.of<AuthController>(context, listen: false).currentUser !=
              null) ...[
            IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: Color(0xFF00E5FF), size: 22),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            const Center(child: NotificationBadge()),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: appProps.currentTabIndex,
              children: [
                const FeedPage(),
                const ChatListPage(),
                const SearchScreen(),
                const ProfilePage(),
              ],
            ),
          ),
          const HomeAdsSection(),
          const BannerAdWidget(),
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
    final auth = Provider.of<AuthController>(context);
    final user = auth.currentUser;
    final locale = AppLocalization.of(context)!;

    final items = [
      {'icon': Icons.dns_rounded, 'label': locale.translate('nav_feed').toUpperCase()},
      {'icon': Icons.chat_bubble_rounded, 'label': locale.translate('chat').toUpperCase()},
      {'icon': Icons.search_rounded, 'label': locale.translate('nav_search').toUpperCase()},
      {
        'icon': Icons.account_circle_rounded,
        'label': locale.translate('nav_profile').toUpperCase(),
        'isProfile': true
      },
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
              final isProfile = item['isProfile'] == true;

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
                        if (isProfile &&
                            user != null &&
                            user.profileImage.isNotEmpty)
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.white.withValues(alpha: 0.2),
                                width: 1.5,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(user.profileImage),
                                fit: BoxFit.cover,
                                colorFilter: isSelected
                                    ? const ColorFilter.mode(
                                        Colors.black, BlendMode.dstIn)
                                    : null,
                              ),
                            ),
                          )
                        else
                          Icon(
                            item['icon'] as IconData,
                            color: isSelected
                                ? Colors.black
                                : Colors.white.withValues(alpha: 0.2),
                            size: 24,
                          ),
                        const SizedBox(height: 8),
                        Text(
                          item['label'] as String,
                          style: AppLocalization.digitalFont(
                            context,
                            color: isSelected
                                ? Colors.black
                                : Colors.white.withValues(alpha: 0.3),
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
                              color: const Color(0xFF00E5FF).withValues(alpha: 0.1),
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
                              Colors.black.withValues(alpha: 0.6)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          ad.title,
                          style: AppLocalization.digitalFont(context,
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
