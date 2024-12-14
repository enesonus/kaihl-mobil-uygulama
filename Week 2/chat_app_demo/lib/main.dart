import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(AIChatApp());
}

class AIChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _messages = []; // Stores user and bot messages
  final api_key = null; // Add your OpenAI API key here
  bool _isLoading = false;

  // Function to send request to the API
  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    final copyMessages = <Map<String, String>>[];

    setState(() {
      _isLoading = true;
      _messages.add({"role": "user", "content": message}); // Add user message
    });

    final systemMessage = {"role": "system", "content": "Hangi dilde konuşulursa konuşulsun Arapça cevap ver"};
    copyMessages.add(systemMessage);
    copyMessages.addAll(_messages);

    print("messages: $_messages");
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $api_key',
      },
      body: json.encode({
        "model": "gpt-4o-mini",
        "messages": copyMessages,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(
          utf8.decode(response.bodyBytes)); // Decoding the response as UTF-8
      final botMessage = data['choices'][0]['message']['content'].trim();

      setState(() {
        _isLoading = false;
        _messages.add(
            {"role": "assistant", "content": botMessage}); // Add bot message
      });
    } else {
      setState(() {
        _isLoading = false;
        _messages.add(
            {"role": "assistant", "content": "Error: Failed to get response."});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Chat', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUserMessage = message["role"] == "user";

                return Align(
                  alignment: isUserMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5.0),
                    padding: EdgeInsets.all(12.0),
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color:
                          isUserMessage ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: isUserMessage
                            ? Radius.circular(15)
                            : Radius.circular(0),
                        bottomRight: isUserMessage
                            ? Radius.circular(0)
                            : Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      message["content"]!,
                      style: TextStyle(
                        color: isUserMessage ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) CupertinoActivityIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.green[100],
                      hintText: 'Enter your message...',
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 15.0),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    final message = _controller.text;
                    _controller.clear();
                    _sendMessage(message);
                  },
                  child: Container(
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
