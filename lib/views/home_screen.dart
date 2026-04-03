import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';
import '../providers/app_provider.dart';
import '../models/ad_model.dart';
import '../theme/app_theme.dart';
import 'feed_page.dart';
import 'chat_list_page.dart';
import 'settings_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfileCompleteness());
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(locale.translate('profile_incomplete'), 
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(locale.translate('complete_to_verify'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale.translate('cancel'), style: const TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 3); // Switch to Settings tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(locale.translate('complete_profile'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  final List<Widget> _pages = [
    const FeedPage(),
    const SearchScreen(),
    const ChatListPage(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;

    final navItems = <_NavItem>[
      _NavItem(
        iconData: FontAwesomeIcons.house,
        label: locale.translate('feed'),
      ),
      _NavItem(
        iconData: FontAwesomeIcons.magnifyingGlass,
        label: locale.translate('explore'),
      ),
      _NavItem(
        iconData: FontAwesomeIcons.commentDots,
        label: locale.translate('chat'),
      ),
      _NavItem(
        iconData: FontAwesomeIcons.gear,
        label: locale.translate('settings'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _pages,
            ),
          ),
          if (_currentIndex == 0) const HomeAdsSection(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        items: navItems,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Bottom Navigation Bar ────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border:
            Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with glow / pill
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: isSelected
                              ? const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 7)
                              : const EdgeInsets.all(7),
                          decoration: isSelected
                              ? BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0x337C4DFF),
                                      Color(0x1A00E5FF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                )
                              : null,
                          child: isSelected
                              ? ShaderMask(
                                  shaderCallback: (b) =>
                                      AppColors.primaryGradient
                                          .createShader(b),
                                  child: FaIcon(
                                    item.iconData,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                )
                              : FaIcon(
                                  item.iconData,
                                  color: AppColors.textMuted,
                                  size: 18,
                                ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontFamily: 'Poppins',
                          ),
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
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

class _NavItem {
  final FaIconData iconData;
  final String label;
  const _NavItem({
    required this.iconData,
    required this.label,
  });
}

// ── Home Ads Banner ──────────────────────────────────────────────────────────

class HomeAdsSection extends StatelessWidget {
  const HomeAdsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final adminController = Provider.of<AdminController>(context);

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
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                      image: NetworkImage(ad.imageUrl), fit: BoxFit.cover),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
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
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
