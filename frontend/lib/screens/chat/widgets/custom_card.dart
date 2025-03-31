import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mental_health_app/screens/chat/chat_with_user.dart';

class CustomCard extends StatelessWidget {
  final String id;
  final String userName;
  final String email;
  final List<String> tags;
  final String aiDescription;
  final double? similarity;

  CustomCard({
    required this.id,
    required this.userName,
    required this.email,
    required this.tags,
    required this.aiDescription,
    required this.similarity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue[900],
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$userName',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                IconButton(
                  onPressed: () {
                    Get.to(ChatwithUser(
                      userName: userName,
                      id: id,
                    ));
                  },
                  icon: Icon(
                    Icons.arrow_circle_right,
                    color: Colors.white,
                  ),
                )
              ],
            ),
            SizedBox(height: 5),
            Text(
              'Email: $email',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            SizedBox(height: 10),
            Wrap(
              spacing: 5,
              children: tags
                  .map((tag) => Chip(
                        label: Text(
                          tag,
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.blueAccent,
                      ))
                  .toList(),
            ),
            SizedBox(height: 10),
            Text(
              'Description:',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              aiDescription,
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 10),
            if (similarity != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Similarity: ${(similarity! * 100).toStringAsFixed(2)}%',
                    style: TextStyle(color: Colors.white),
                  ),
                  Icon(
                    Icons.star,
                    color: similarity! > 0.7 ? Colors.yellow : Colors.grey,
                  ),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}
