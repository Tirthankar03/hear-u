import 'package:flutter/material.dart';
import 'package:mental_health_app/api.dart';
import 'package:mental_health_app/constants.dart';
import 'package:mental_health_app/screens/chat/widgets/custom_card.dart';
import 'dart:math';

class BlinkingStar extends StatelessWidget {
  const BlinkingStar({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.star, color: Colors.white, size: 5);
  }
}

class ChatHistory extends StatefulWidget {
  const ChatHistory({super.key});

  @override
  _ChatHistoryState createState() => _ChatHistoryState();
}

class _ChatHistoryState extends State<ChatHistory> {
  late Future<List<Map<String, dynamic>>> chatPartnersFuture;
  final Random _random = Random();

  Future<List<Map<String, dynamic>>> getChatPartnersData() async {
    try {
      return await Api().getChatPartners(AppConstants.userId ?? "") ?? [];
    } catch (e) {
      throw Exception("Error fetching chat partners: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    chatPartnersFuture = getChatPartnersData();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
          // Back Button
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
          // Chat Partners List
          Positioned(
            top: screenHeight * 0.1,
            left: 0,
            right: 0,
            bottom: 0,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: chatPartnersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No chat partners found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final chatPartners = snapshot.data!;
                return SingleChildScrollView(
                  child: Column(
                    children: chatPartners.map((partnerData) {
                      final partner = partnerData['partner'];
                      return CustomCard(
                        id: partner['id'],
                        userName: partner['randname'],
                        email: partner['email'] ?? 'No email provided',
                        tags: List<String>.from(partner['tags']),
                        aiDescription: partner['ai_description'],
                        similarity:
                            null, // No similarity field in this response
                      );
                    }).toList(),
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
