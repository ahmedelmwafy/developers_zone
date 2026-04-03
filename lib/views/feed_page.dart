import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/post_controller.dart';
import '../models/post_model.dart';
import '../providers/app_provider.dart';
import 'create_post_screen.dart';
import 'notifications_page.dart';
import 'components/post_card.dart';
import '../controllers/auth_controller.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final postController = Provider.of<PostController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate('global_feed')),
        actions: [
          DropdownButton<String>(
            value: _filter,
            hint: const Icon(Icons.filter_list, color: Colors.white),
            dropdownColor: const Color(0xFF0F0E17),
            items: ['Flutter Developer', 'Backend Developer', 'UX Designer', 'Mobile Developer'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(color: Colors.white)));
            }).toList(),
            onChanged: (val) => setState(() => _filter = val),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsPage())),
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreatePostScreen())),
          ),
        ],
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: postController.getGlobalFeed(
          positionFilter: _filter,
          blockedUsers: Provider.of<AuthController>(context).currentUser?.blockedUsers ?? [],
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text(locale.translate('no_posts_found')));
          
          final posts = snapshot.data!;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(post: post);
            },
          );
        },
      ),
    );
  }
}
