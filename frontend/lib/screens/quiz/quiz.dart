// QuizScreen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mental_health_app/api.dart';
import 'package:mental_health_app/navigation.dart';
import 'package:mental_health_app/screens/chat/chat.dart';

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final box = GetStorage(); // Initialize GetStorage
  bool _isLoading = true;
  String? _sessionId;
  String _question = "";
  List<String> _options = [];
  String? _selectedOption;
  int _questionCount = 0;

  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  Future<void> _startQuiz() async {
    setState(() => _isLoading = true);
    try {
      final response = await Api.startMoodQuiz();
      if (response['success'] == true) {
        _processResponse(response);
        // Save session ID initially
        _sessionId = response['sessionId'];
        box.write('session_quiz_id', _sessionId);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error starting quiz: $e')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _submitAnswer() async {
    if (_selectedOption == null || _sessionId == null) return;

    setState(() => _isLoading = true);
    try {
      final response = await Api.submitQuizAnswer(
        _sessionId!,
        _selectedOption!,
      );
      if (response['success'] == true) {
        _questionCount++;
        if (response.containsKey('mood') && _questionCount >= 5) {
          // Final response received, navigate to ChatScreen
          final navigationController = Get.find<NavigationController>();
          navigationController.selectedIndex.value = 1;
          Get.to(
            () => ChatScreen(
              initialMessage: response['message'],
              sessionId: _sessionId,
            ),
          );
          // Clean up storage after quiz completion
          box.remove('session_quiz_id');
        } else {
          _processResponse(response);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting answer: $e')));
    }
    setState(() => _isLoading = false);
  }

  void _processResponse(Map<String, dynamic> response) {
    // Use stored session ID if available
    _sessionId = box.read('session_quiz_id') ?? response['sessionId'];
    String message = response['message'];

    // Save session ID on every response just to be safe
    box.write('session_quiz_id', _sessionId);

    // Improved parsing for question and options
    List<String> parts = message.split(RegExp(r'(?=[a-d]\))'));
    _question = parts[0].trim();
    _options =
        parts.sublist(1).map((part) => part.split(')')[1].trim()).toList();

    setState(() {
      _selectedOption = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Color(0xFF075E54), title: Text("Quiz")),
      body: Container(
        color: Colors.black,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _question,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    ..._options.asMap().entries.map((entry) {
                      int idx = entry.key;
                      String option = entry.value;
                      return RadioListTile<String>(
                        title: Text(
                          option,
                          style: TextStyle(color: Colors.white),
                        ),
                        value: String.fromCharCode(97 + idx),
                        groupValue: _selectedOption,
                        activeColor: Colors.white,
                        onChanged: (value) {
                          setState(() {
                            _selectedOption = value;
                          });
                        },
                      );
                    }).toList(),
                    Spacer(),
                    Center(
                      child: ElevatedButton(
                        onPressed:
                            _selectedOption != null ? _submitAnswer : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF075E54),
                          padding: EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          'Submit',
                          style: TextStyle(color: Colors.white),
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
