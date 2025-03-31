import 'package:flutter/material.dart';
import 'package:mental_health_app/constants.dart';
import 'package:mental_health_app/screens/chat/widgets/custom_card.dart';
import 'dart:math';
import 'package:mental_health_app/screens/community/api_services.dart';

class BlinkingStar extends StatelessWidget {
  const BlinkingStar({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star, color: Colors.white, size: 5);
  }
}

class TalkChat extends StatefulWidget {
  final String sessionId;

  const TalkChat({required this.sessionId, super.key});

  @override
  _TalkChatState createState() => _TalkChatState();
}

class _TalkChatState extends State<TalkChat> {
  late Future<List<Map<String, dynamic>>>
      similarUsersFuture; // Changed to Future
  final Random _random = Random();

  Future<List<Map<String, dynamic>>> getOtherUsers() async {
    try {
      return await ApiService.findSimilarUsers(
          AppConstants.userId ?? "", widget.sessionId);
    } catch (e) {
      throw Exception("Error fetching users: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    similarUsersFuture = getOtherUsers(); // Assign the Future
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          Positioned(
            top: screenHeight * 0.1,
            left: 0,
            right: 0,
            bottom: 0,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: similarUsersFuture, // Using the Future
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.white)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                      child: Text('No similar users found',
                          style: TextStyle(color: Colors.white)));
                }

                final similarUsers = snapshot.data!;
                return SingleChildScrollView(
                  child: Column(
                    children: similarUsers
                        .map((user) => CustomCard(
                              id: user['id'],
                              userName: user['randname'],
                              email: user['email'] ?? 'No email provided',
                              tags: List<String>.from(user['tags']),
                              aiDescription: user['ai_description'],
                              similarity: user['similarity'] / 100,
                            ))
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
