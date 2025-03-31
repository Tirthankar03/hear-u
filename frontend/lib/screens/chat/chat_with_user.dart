import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mental_health_app/api.dart';
import 'package:mental_health_app/constants.dart';

class ChatwithUser extends StatefulWidget {
  final String userName;
  final String id;

  const ChatwithUser({required this.userName, required this.id, super.key});

  @override
  _ChatwithUserState createState() => _ChatwithUserState();
}

class _ChatwithUserState extends State<ChatwithUser> {
  final TextEditingController _controller = TextEditingController();
  final Random _random = Random();
  List<ChatMessage> _messages = [];
  String? chatId;
  Timer? _timer;
  List<String> _existingMessageIds = []; // Track existing message IDs

  @override
  void initState() {
    super.initState();
    initFunc();
    _startPeriodicChatFetch();
  }

  void initFunc() async {
    chatId =
        await Api.startUserChat(AppConstants.userId ?? "", widget.id) ?? "";
    if (chatId != null) {
      _fetchInitialChatHistory();
    }
  }

  void _startPeriodicChatFetch() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchChatHistory();
    });
  }

  Future<void> _fetchInitialChatHistory() async {
    final messages =
        await Api.getChatHistory(AppConstants.userId ?? "", widget.id);
    if (messages != null) {
      setState(() {
        _messages = messages.map((msg) {
          _existingMessageIds.add(msg['messageId']);
          return ChatMessage(
            text: msg['content'],
            isMe: msg['senderId'] == AppConstants.userId,
            username: msg['senderId'] == AppConstants.userId
                ? AppConstants.username ?? "You"
                : widget.userName,
          );
        }).toList();
      });
    }
  }

  Future<void> _fetchChatHistory() async {
    final messages =
        await Api.getChatHistory(AppConstants.userId ?? "", widget.id);
    if (messages != null) {
      final newMessages = messages
          .where((msg) => !_existingMessageIds.contains(msg['messageId']))
          .toList();
      if (newMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(newMessages.map((msg) {
            _existingMessageIds.add(msg['messageId']);
            return ChatMessage(
              text: msg['content'],
              isMe: msg['senderId'] == AppConstants.userId,
              username: msg['senderId'] == AppConstants.userId
                  ? AppConstants.username ?? "You"
                  : widget.userName,
            );
          }));
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Scaffold(
        body: Stack(
          children: [
            // Gradient Background
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
            // Blinking Stars
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

            // Chat Body
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _messages[_messages.length - 1 - index];
                    },
                  ),
                ),
                _buildInputArea(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints:
                  const BoxConstraints(minHeight: 60.0, maxHeight: 120.0),
              decoration: BoxDecoration(
                border: Border.all(width: .8, color: Colors.white70),
                color: Colors.black,
                borderRadius: BorderRadius.circular(25.0),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                style: const TextStyle(fontSize: 14.0, color: Colors.white),
                decoration: const InputDecoration(
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
          const SizedBox(width: 8.0),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF075E54),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              onPressed: () async {
                if (_controller.text.isNotEmpty && chatId != null) {
                  String content = _controller.text;
                  _controller.clear();

                  final i = await Api.sendMessageToUser(
                      chatId!, AppConstants.userId ?? "", content);
                  setState(() {});
                }
              },
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
    return const Icon(Icons.star, color: Colors.white, size: 5);
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isMe;
  final String username;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.username,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
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
                const SizedBox(height: 4.0),
                Text(text, style: const TextStyle(fontSize: 14.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
