import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_model.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const ChatDetailScreen({required this.chatId, required this.otherUserId, super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();

  void _sendMessage() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final chatController = Provider.of<ChatController>(context, listen: false);
    
    if (_messageController.text.trim().isEmpty) return;

    final message = MessageModel(
      id: '', // Will be generated
      senderId: authController.currentUser!.uid,
      receiverId: widget.otherUserId,
      text: _messageController.text.trim(),
      createdAt: DateTime.now(),
      isSeen: false,
    );

    await chatController.sendMessage(widget.chatId, message);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chatController = Provider.of<ChatController>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserId)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: chatController.getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                final currentUserId = Provider.of<AuthController>(context).currentUser!.uid;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF673AB7) : const Color(0xFF16161A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(message.text, style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 5),
                            Text(message.createdAt.toIso8601String().split('T').last.substring(0, 5), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.image, color: Color(0xFF673AB7)), onPressed: () {}),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Type a message...', hintStyle: const TextStyle(color: Colors.grey)),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFF673AB7)), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
