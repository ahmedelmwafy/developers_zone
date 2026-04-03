import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'create_post_screen.dart';
import 'notifications_page.dart';
import '../controllers/auth_controller.dart';
import 'components/post_card.dart';
import 'components/shimmer_loading.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final postController = Provider.of<PostController>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.code, size: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                  child: const Text('Dev Zone', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.bell, size: 20),
                color: AppColors.textSecondary,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage())),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.squarePlus, size: 20),
                color: AppColors.textSecondary,
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen())),
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: Colors.white.withValues(alpha: 0.06), height: 1),
            ),
          ),
          
          // Feed
          StreamBuilder<List<PostModel>>(
            stream: postController.getGlobalFeed(
              blockedUsers: Provider.of<AuthController>(context).currentUser?.blockedUsers ?? [],
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const PostShimmer(),
                    childCount: 4,
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.article_outlined, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(locale.translate('no_posts_found'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }
              final posts = snapshot.data!;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => PostCard(post: posts[index]),
                  childCount: posts.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
