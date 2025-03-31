import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mental_health_app/api.dart';

import 'package:mental_health_app/constants.dart';
import 'package:mental_health_app/screens/chat/talk_chat.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  final String? sessionId;

  ChatScreen({this.initialMessage, this.sessionId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final Random _random = Random();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? sessionId;

  @override
  void initState() {
    super.initState();
    if (widget.sessionId != null) {
      sessionId = widget.sessionId;
      if (widget.initialMessage != null) {
        _messages.add(
          ChatMessage(
            text: widget.initialMessage!,
            isMe: false,
            username: "Saheli",
          ),
        );
      }
    } else {
      _startNewChat();
    }
  }

  Future<void> _startNewChat() async {
    setState(() {
      _messages.clear();
      _isTyping = true;
    });

    try {
      final response = await Api.startChat();
      debugPrint("Chat response: ${response.toString()}");
      if (response['success'] == true) {
        setState(() {
          sessionId = response['sessionId'];
          debugPrint("Session ID: ${sessionId}");
          _isTyping = false;

          _messages.add(
            ChatMessage(
              text: response['response'],
              isMe: false,
              username: "Saheli",
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: "Error starting chat: $e",
            isMe: false,
            username: "Saheli",
          ),
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isNotEmpty && sessionId != null) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: _controller.text,
            isMe: true,
            username: AppConstants.username ?? "Username",
          ),
        );
        _isTyping = true;
      });

      try {
        final text = _controller.text;
        _controller.clear();
        final response = await Api.sendAnswer(sessionId!, text);
        if (response['success'] == true) {
          debugPrint("Chating : ${response.toString()}");
          setState(() {
            _isTyping = false;
            _messages.add(
              ChatMessage(
                text: response['message'],
                isMe: false,
                username: "Saheli",
              ),
            );
          });
        }
      } catch (e) {
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text: "Error sending message: $e",
              isMe: false,
              username: "Saheli",
            ),
          );
        });
      }

      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Chat", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: () {
                debugPrint("Session ID: ${sessionId}");
                Get.to(TalkChat(
                  sessionId: '${sessionId}',
                ));
              },
              icon: Icon(Icons.join_right, color: Colors.white)),
          SizedBox(
            width: 5,
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: _startNewChat,
            tooltip: "Start New Chat",
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.0),
            child: Text(
              "New Chat",
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF081423), Color(0xFF000000)],
                  stops: [0.3, 1],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.4,
            child: Stack(
              children: List.generate(
                50,
                (index) => Positioned(
                  top: _random.nextDouble() * (screenHeight * 0.4),
                  left: _random.nextDouble() * screenWidth,
                  child: const BlinkingStar(),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isTyping && index == 0) {
                      return TypingIndicator();
                    }
                    final messageIndex = _isTyping ? index - 1 : index;
                    return _messages[_messages.length - 1 - messageIndex];
                  },
                ),
              ),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints(minHeight: 60.0, maxHeight: 120.0),
              decoration: BoxDecoration(
                border: Border.all(width: .8, color: Colors.white70),
                color: Colors.black,
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                style: TextStyle(fontSize: 14.0, color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Type a message",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 15.0,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF075E54),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send),
              color: Colors.white,
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class BlinkingStar extends StatelessWidget {
  const BlinkingStar({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star, color: Colors.white, size: 5);
  }
}

// ChatMessage and TypingIndicator classes remain the same as previous code
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isMe;
  final String username;

  ChatMessage({required this.text, required this.isMe, required this.username});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isMe ? Color(0xFFDCF8C6) : Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: TextStyle(fontSize: 12.0, color: Colors.grey[600]),
                ),
                SizedBox(height: 4.0),
                Text(text, style: TextStyle(fontSize: 14.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Text("Saheli is typing"),
                SizedBox(width: 5),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
