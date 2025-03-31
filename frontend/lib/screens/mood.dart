import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mental_health_app/controllers/all_controller.dart';
// Assuming NavigationScreen is in navigation.dart
import 'package:mental_health_app/navigation.dart';

class MoodSelectionPage extends StatefulWidget {
  const MoodSelectionPage({super.key});

  @override
  State<MoodSelectionPage> createState() => _MoodSelectionPageState();
}

class _MoodSelectionPageState extends State<MoodSelectionPage> {
  int? _selectedMood;
  final _storage = GetStorage();
  final allController = Get.find<AllController>();

  final List<Map<String, dynamic>> _moods = [
    {'value': 1, 'label': 'very bad', 'emoji': '😢'},
    {'value': 2, 'label': 'bad', 'emoji': '😞'},
    {'value': 3, 'label': 'neutral', 'emoji': '😐'},
    {'value': 4, 'label': 'good', 'emoji': '😊'},
    {'value': 5, 'label': 'very good', 'emoji': '😊👍'},
  ];

  Future<void> submitMood(BuildContext context) async {
    allController.toggleModdSubmit();
    final String? userId = await _storage.read('userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
      return;
    }

    if (_selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a mood')),
      );
      return;
    }

    const String baseUrl = 'https://hearu-backend.onrender.com';
    final String apiUrl = '$baseUrl/api/mood/$userId';

    final selectedMoodData = _moods.firstWhere(
      (mood) => mood['value'] == _selectedMood,
    );
    String moodLabel = selectedMoodData['label'];
    _storage.write('selectedMood', _selectedMood);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'mood': moodLabel,
        },
      );

      final responseData = jsonDecode(response.body);
      debugPrint(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NavigationScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Failed to record mood',
            ),
          ),
        );
      }
      allController.toggleModdSubmit();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How Are You Feeling?'),
        backgroundColor: const Color(0xFF07233B),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF07233B),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select Your Mood',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                alignment: WrapAlignment.center,
                children: _moods.map((mood) {
                  final isSelected = _selectedMood == mood['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = mood['value'];
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.blueAccent.withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            mood['emoji'],
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            mood['label'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              Obx(
                () => ElevatedButton(
                  // Changed this line to use an anonymous function
                  onPressed: () => submitMood(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: allController.moodSubmit.value
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
