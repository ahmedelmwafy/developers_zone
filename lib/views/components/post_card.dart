import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post_model.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/post_controller.dart';
import '../../providers/app_provider.dart';
import '../post_details_page.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  const PostCard({required this.post, super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);
    final postController = Provider.of<PostController>(context);
    final locale = AppLocalization.of(context)!;
    final currentUser = authController.currentUser;
    final isMe = currentUser?.uid == post.authorId;
    final isLiked = currentUser != null && post.likes.contains(currentUser.uid);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: const Color(0xFF16161A),
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailsPage(post: post))),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: post.authorProfileImage.isNotEmpty ? NetworkImage(post.authorProfileImage) : null,
                    child: post.authorProfileImage.isEmpty ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(post.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          if (post.isAuthorVerified) const SizedBox(width: 4),
                          if (post.isAuthorVerified) const Icon(Icons.verified, color: Colors.blue, size: 16),
                        ],
                      ),
                      Text(post.authorPosition, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  if (!isMe && currentUser != null) 
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (val) {
                        if (val == 'block') {
                          authController.blockUser(post.authorId);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(value: 'block', child: Text(locale.translate('block'))),
                      ],
                    )
                  else
                    Text(post.createdAt.toIso8601String().split('T').first, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 10),
              Text(post.text, style: const TextStyle(color: Colors.white)),
              if (post.images.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: post.images.map((img) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(img, width: 250, height: 180, fit: BoxFit.cover),
                      ),
                    )).toList(),
                  ),
                ),
              const SizedBox(height: 10),
              const Divider(color: Colors.grey, thickness: 0.1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: currentUser == null ? null : () => postController.togglePostLike(post.id, currentUser.uid, !isLiked),
                    icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey),
                    label: Text(post.likes.length.toString(), style: const TextStyle(color: Colors.grey)),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PostDetailsPage(post: post))),
                    icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                    label: Text(post.commentCount.toString(), style: const TextStyle(color: Colors.grey)),
                  ),
                  IconButton(
                    onPressed: () {}, // Share feature placeholder
                    icon: const Icon(Icons.share_outlined, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
