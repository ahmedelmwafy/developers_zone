import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';
import '../providers/app_provider.dart';
import '../controllers/auth_controller.dart';
import 'create_post_screen.dart';
import 'components/post_card.dart';
import 'components/shimmer_loading.dart';
import 'profile_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final postController = Provider.of<PostController>(context);
    final user = Provider.of<AuthController>(context).currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildDigitalAppBar(context, user, locale),
              _buildFeedTabs(locale),
              _buildFeedContent(postController, user, locale),
            ],
          ),
          _buildFloatingActionButton(context),
        ],
      ),
    );
  }

  Widget _buildDigitalAppBar(
      BuildContext context, dynamic user, AppLocalization locale) {
    return SliverAppBar(
      floating: true,
      snap: true,
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
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ProfilePage(userId: user?.uid ?? '')),
          ),
          child: Container(
            margin: const EdgeInsets.only(right: 24),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF161616),
              backgroundImage: (user?.profileImage?.isNotEmpty ?? false)
                  ? NetworkImage(user!.profileImage)
                  : null,
              child: (user?.profileImage?.isEmpty ?? true)
                  ? const Icon(Icons.person_rounded,
                      color: Colors.white30, size: 18)
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedTabs(AppLocalization locale) {
    final tabs = [
      locale.translate('TAB_GLOBAL'),
      locale.translate('TAB_FOLLOWING'),
      locale.translate('TAB_TRENDING')
    ];
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00E5FF).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tabs[index].toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: isSelected
                        ? const Color(0xFF00E5FF)
                        : Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFeedContent(
      PostController postController, dynamic user, AppLocalization locale) {
    Stream<List<PostModel>> feedStream;
    
    if (_selectedTab == 1 && user != null) {
      feedStream = postController.getFollowingFeed(
        userId: user.uid,
        followingIds: List<String>.from(user.following),
      );
    } else {
      feedStream = postController.getGlobalFeed(
        blockedUsers: List<String>.from(user?.blockedUsers ?? []),
      );
    }

    return StreamBuilder<List<PostModel>>(
      stream: feedStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => const PostShimmer(),
              childCount: 4,
            ),
          );
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.terminal_rounded,
                      size: 48, color: Colors.white.withOpacity(0.05)),
                  const SizedBox(height: 16),
                  Text(
                    _selectedTab == 1
                        ? locale.translate('NO_CONNECTIONS_FOUND')
                        : locale.translate('NO_COMMITS_FOUND'),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => PostCard(post: posts[index]),
              childCount: posts.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: GestureDetector(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const CreatePostScreen())),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF).withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
