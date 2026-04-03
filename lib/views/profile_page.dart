import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';
import '../providers/app_provider.dart';
import 'edit_profile_screen.dart';
import 'components/post_card.dart';

class ProfilePage extends StatelessWidget {
  final String? userId; 
  const ProfilePage({this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final user = userId == null ? authController.currentUser : null; 
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final postController = Provider.of<PostController>(context);
    final locale = AppLocalization.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate('profile')),
        actions: [
          if (userId == null)
            IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
          if (userId == null)
            IconButton(icon: const Icon(Icons.logout), onPressed: () => authController.logout()),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50, 
              backgroundImage: user.profileImage.isNotEmpty ? NetworkImage(user.profileImage) : null, 
              child: user.profileImage.isEmpty ? const Icon(Icons.person, size: 50) : null
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                if (user.isVerified) const SizedBox(width: 5),
                if (user.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 20),
              ],
            ),
            Text(user.position, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            Text('${user.city}, ${user.country}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (user.socialLinks?['github'] != null) IconButton(icon: const Icon(Icons.link), onPressed: () {}),
                if (user.socialLinks?['linkedin'] != null) IconButton(icon: const Icon(Icons.work), onPressed: () {}),
              ],
            ),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Divider(color: Colors.grey),
            ),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    tabs: [
                      Tab(text: locale.translate('bio')),
                      Tab(text: locale.translate('posts')),
                    ],
                  ),
                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      children: [
                        Padding(padding: const EdgeInsets.all(20.0), child: Text(user.bio, style: const TextStyle(color: Colors.white))),
                        StreamBuilder<List<PostModel>>(
                          stream: postController.getUserPosts(user.uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                            if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text(locale.translate('no_posts_found')));
                            final posts = snapshot.data!;
                            return ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: posts.length,
                              itemBuilder: (context, index) => PostCard(post: posts[index]),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
