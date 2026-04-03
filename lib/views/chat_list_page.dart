import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';
import '../providers/app_provider.dart';
import 'chat_detail_screen.dart';

class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalization.of(context)!;
    final currentUser = Provider.of<AuthController>(context).currentUser;
    if (currentUser == null) return const Center(child: Text('Please login to chat'));

    final chatController = Provider.of<ChatController>(context);

    return Scaffold(
      appBar: AppBar(title: Text(locale.translate('chat'))),
      body: StreamBuilder<List<ChatModel>>(
        stream: chatController.getUserChats(currentUser.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No conversations yet'));
          final chats = snapshot.data!;
          
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final otherUserId = chat.users.firstWhere((id) => id != currentUser.uid);
              
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(otherUserId, style: const TextStyle(color: Colors.white)), // Better to fetch name by id
                subtitle: Text(chat.lastMessage, style: TextStyle(color: chat.isSeen ? Colors.grey : Colors.white, fontWeight: chat.isSeen ? FontWeight.normal : FontWeight.bold)),
                trailing: Text(chat.lastMessageTime.toIso8601String().split('T').first, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatDetailScreen(chatId: chat.id, otherUserId: otherUserId))),
              );
            },
          );
        },
      ),
    );
  }
}
