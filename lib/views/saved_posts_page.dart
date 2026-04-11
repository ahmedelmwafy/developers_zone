import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../providers/app_provider.dart';
import 'components/post_card.dart';
import 'components/shimmer_loading.dart';

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final user = auth.currentUser;
    final locale = AppLocalization.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        title: Text(
          locale.translate('SAVED_MANIFESTS_CAPS'),
          style: AppLocalization.digitalFont(
            context,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00E5FF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null || user.savedPosts.isEmpty
          ? _buildEmptyState(context, locale)
          : _buildSavedList(context, user.savedPosts),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalization locale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(Icons.bookmark_outline_rounded,
                color: Colors.white.withValues(alpha: 0.1), size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            locale.translate('no_saved_posts'),
            style: AppLocalization.digitalFont(
              context,
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            locale.translate('saved_manifests_empty_body'),
            style: AppLocalization.digitalFont(context, 
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedList(BuildContext context, List<String> savedIds) {
    return StreamBuilder<List<PostModel>>(
      stream: FirestoreService().streamSavedPosts(savedIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: 3,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: PostShimmer(),
            ),
          );
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) return _buildEmptyState(context, AppLocalization.of(context)!);

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: PostCard(
                  key: ValueKey(posts[index].id),
                  post: posts[index],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
