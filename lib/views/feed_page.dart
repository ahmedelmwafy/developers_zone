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
              _buildFeedTabs(locale),
              _buildFeedContent(postController, user, locale),
            ],
          ),
          _buildFloatingActionButton(context),
        ],
      ),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00E5FF).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      tabs[index].toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        color: isSelected
                            ? const Color(0xFF00E5FF)
                            : Colors.white.withOpacity(0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
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
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const PostShimmer(),
                childCount: 4,
              ),
            ),
          );
        }

        List<PostModel> posts = List.from(snapshot.data ?? []);

        // Sort by Trending (Likes) if tab is selected
        if (_selectedTab == 2) {
          posts.sort((a, b) => b.likes.length.compareTo(a.likes.length));
        }

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
