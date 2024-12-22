import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(AIChatApp());
}

class AIChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: ChatListScreen(),
    );
  }
}

class ChatListScreen extends StatelessWidget {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('chats')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return Center(
              child: Text('No chats yet. Create a new chat!'),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final chatTitle = chat['title'] as String?;
              final messages = (chat['messages'] as List?) ?? [];
              final lastMessage = messages.isNotEmpty
                  ? messages.last['text'] as String
                  : 'New Chat';
              final timestamp = (chat['timestamp'] as Timestamp).toDate();

              return ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text(chatTitle ?? 'Chat ${index + 1}'),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${timestamp.day}/${timestamp.month}/${timestamp.year}",
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline),
                      onPressed: () async {
                        // Show confirmation dialog
                        final delete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Delete Chat?'),
                            content: Text('This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('CANCEL'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('DELETE'),
                              ),
                            ],
                          ),
                        );

                        if (delete == true) {
                          await _db
                              .collection('chats')
                              .doc(chats[index].id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chat deleted')),
                          );
                        }
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chatId: chats[index].id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final docRef = await _db.collection('chats').add({
            'messages': [],
            'timestamp': DateTime.now(),
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(chatId: docRef.id),
            ),
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String chatId;

  ChatScreen({required this.chatId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isLoading = false;
  final apiKey = null;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final DocumentSnapshot chat =
          await _db.collection('chats').doc(widget.chatId).get();

      setState(() {
        final chatData = chat.data() as Map<String, dynamic>;
        messages = List<Map<String, dynamic>>.from(chatData['messages'] ?? []);
      });
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage(String messageText) async {
    if (messageText.isEmpty) return;

    _messageController.clear();
    setState(() {
      _isLoading = true;
    });

    try {
      final messageData = {
        'text': messageText,
        'isUser': true,
        'timestamp': DateTime.now(),
      };

      setState(() {
        messages.add(messageData);
      });

      await _db.collection('chats').doc(widget.chatId).update({
        'messages': FieldValue.arrayUnion([messageData]),
        'timestamp': DateTime.now(),
      });

      // Convert chat history to OpenAI message format
      List<Map<String, String>> chatHistory = messages.map((msg) {
        return {
          "role": msg['isUser'] ? "user" : "assistant",
          "content": msg['text'] as String
        };
      }).toList();

      // Add the new message
      chatHistory.add({"role": "user", "content": messageText});

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          "model": "gpt-4o-mini",
          "messages": chatHistory,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final aiMessage = data['choices'][0]['message']['content'];

        final aiMessageData = {
          'text': aiMessage,
          'isUser': false,
          'timestamp': DateTime.now(),
        };

        setState(() {
          messages.add(aiMessageData);
        });

        await _db.collection('chats').doc(widget.chatId).update({
          'messages': FieldValue.arrayUnion([aiMessageData]),
          'timestamp': DateTime.now(),
        });
      }
    } catch (e) {
      print('Error sending message: $e');
      final errorMessageData = {
        'text': 'Error: Could not get AI response',
        'isUser': false,
        'timestamp': DateTime.now(),
      };

      setState(() {
        messages.add(errorMessageData);
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUserMessage = message['isUser'] as bool;

                return Align(
                  alignment: isUserMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUserMessage ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['text'] as String,
                      style: TextStyle(
                        color: isUserMessage ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () => _sendMessage(_messageController.text),
                  child: Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
