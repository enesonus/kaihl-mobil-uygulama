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
      title: 'Simple AI Chat',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Controller for the text input
  TextEditingController _messageController = TextEditingController();

  // Store messages in a List
  List<Map<String, dynamic>> messages = [];

  String chatId = DateTime.now().millisecondsSinceEpoch.toString();

  // Reference to Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoading = false;
  final api_key = null; // Add your OpenAI API key here

  // Load existing messages when screen opens
  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // Function to load messages from Firebase
  Future<void> _loadMessages() async {
    try {
      // Get messages from Firebase
      try {
        await _db.collection('chats').doc(chatId).get();
      } catch (e) {
        await _db.collection('chats').add({
          'messages': [],
          'timestamp': DateTime.now(),
        });
      }

      final QuerySnapshot snapshot = await _db
          .collection('chats')
          .orderBy('timestamp', descending: false)
          .get();

      final latestChat = snapshot.docs.last;
      chatId = latestChat.id;

      // Convert to List of Maps and update state
      setState(() {
        final firebaseChat = latestChat.data() as Map<String, dynamic>;
        messages = firebaseChat['messages'] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  // Function to send message
  Future<void> _sendMessage(String messageText) async {
    if (messageText.isEmpty) return;

    _messageController.clear();
    setState(() {
      _isLoading = true;
    });

    try {
      // Create message data
      final messageData = {
        'text': messageText,
        'isUser': true,
        'timestamp': DateTime.now(),
      };

      // Save to Firebase
      await _db.collection('chats').doc(chatId).update({
        'messages': FieldValue.arrayUnion([messageData]),
      });

      // Update local state
      setState(() {
        messages.add(messageData);
      });

      // Get AI response
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          "model": "gpt-4",
          "messages": [
            {"role": "user", "content": messageText}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final aiMessage = data['choices'][0]['message']['content'];

        // Create AI message data
        final aiMessageData = {
          'text': aiMessage,
          'isUser': false,
          'timestamp': DateTime.now(),
        };

        // Save AI message to Firebase
        await _db.collection('chats').doc(chatId).update({
          'messages': FieldValue.arrayUnion([messageData]),
        });

        // Update local state
        setState(() {
          messages.add(aiMessageData);
        });
      }
    } catch (e) {
      // Handle error by showing error message
      print('Error sending message: $e');
      final errorMessageData = {
        'text': 'Error: Could not get AI response',
        'isUser': false,
        'timestamp': DateTime.now(),
      };

      await _db.collection('messages').add(errorMessageData);
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
        title: Text('Simple AI Chat'),
        // Add refresh button to reload messages
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isUserMessage = message['isUser'] as bool;

                return Align(
                  alignment: isUserMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUserMessage ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
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

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          // Message input
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => _sendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
