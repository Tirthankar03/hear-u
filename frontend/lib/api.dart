import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mental_health_app/constants.dart';

class Api {
  static const String _baseUrl = 'https://hearu-backend.onrender.com';

  Future<bool> signup(BuildContext context, String username, String password,
      String email) async {
    try {
      // Create a multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/api/auth/signup'),
      );

      // Add fields to the form data
      request.fields['username'] = username;
      request.fields['password'] = password;
      request.fields['email'] = email;

      // Log request headers to verify Content-Type
      debugPrint("Request Headers: ${request.headers}");

      // Send the request and get the response
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(responseBody);
        debugPrint("SignUP Response: ${responseData.toString()}");

        if (responseData['success'] == true) {
          AppConstants.setUserId(responseData['data']['user'][0]['id']);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User created successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Failed to create user'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          return false;
        }
      } else {
        debugPrint("SignUP Response Headers: ${response.headers}");
        debugPrint("SignUP Response Body: $responseBody");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
  }

  // Updated login function using GetStorage
  Future<bool> login(
    BuildContext context,
    String username,
    String password,
  ) async {
    try {
      var formData = {'username': username, 'password': password};

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        body: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          print(1);
          debugPrint(responseData.toString());

          // Save username and randname
          AppConstants.setUsername(responseData['data']['user']['username']);
          AppConstants.setRandname(responseData['data']['user']['randname']);
          AppConstants.setUserId(responseData['data']['user']['id']);
          AppConstants.setDescription(
              responseData['data']['user']['description']);
          AppConstants.setTags(responseData['data']['user']['tags']);
          AppConstants.setEmail(responseData['data']['user']['email']);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged in successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ?? 'Failed to login'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
          return false;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return false;
    }
  }

  Future<List<Map<String, dynamic>>?> getChatPartners(String userId) async {
    final url = Uri.parse('$_baseUrl/api/chats/chat-partners/$userId');

    try {
      // Make the GET request
      final response = await http.get(url);

      // Parse the response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('Response Body: ${response.body}');
        return List<Map<String, dynamic>>.from(responseData['partners']);
      } else {
        // Failure case: print error and return null
        print('Failed to fetch chat partners:');
        print('Response: $responseData');
        print('Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Error case: print error and return null
      print('Error fetching chat partners: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getChatHistory(
      String userId, String otherUserId) async {
    final url =
        Uri.parse('$_baseUrl/api/chats/chat-history/$userId/$otherUserId');

    try {
      // Make the GET request
      final response = await http.get(url);

      // Parse the response
      final responseData = jsonDecode(response.body);
      debugPrint("Chat History: ${responseData}");

      if (response.statusCode == 200 && responseData['success'] == true) {
        debugPrint("Chat History: ${responseData}");
        return List<Map<String, dynamic>>.from(responseData['messages']);
      } else {
        // Failure case: print error and return null
        print('Failed to fetch chat history:');
        print('Response: $responseData');
        print('Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Error case: print error and return null
      print('Error fetching chat history: $e');
      return null;
    }
  }

  static Future<bool> sendMessageToUser(
      String chatId, String senderId, String content) async {
    final url = Uri.parse('$_baseUrl/api/chats/send-message');

    try {
      // Create a multipart request
      var request = http.MultipartRequest('POST', url);

      // Add fields to the form data
      request.fields['chatId'] = chatId;
      request.fields['senderId'] = senderId;
      request.fields['content'] = content;

      // Send the request and get the response
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // Parse the response
      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200 && responseData['success'] == true) {
        debugPrint("User Response: ${responseData.toString()}");
        return true;
      } else {
        // Failure case: print error and return false
        print('Failed to send message:');
        print('Response: $responseData');
        print('Status Code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      // Error case: print error and return false
      print('Error sending message: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> startMoodQuiz() async {
    final url = Uri.parse('$_baseUrl/api/mood/start');
    final response = await http.post(
      url,
      body: {'userId': AppConstants.userId ?? ""},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start quiz: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> submitQuizAnswer(
    String sessionId,
    String answer,
  ) async {
    final url = Uri.parse('$_baseUrl/api/mood/answer/$sessionId?isQuiz=true');
    final response = await http.post(url, body: {'answer': answer});

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit quiz answer: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> startChat() async {
    final url = Uri.parse('$_baseUrl/api/mood/start/chat');
    final response = await http.post(
      url,
      body: {'userId': AppConstants.userId ?? ""},
    );

    if (response.statusCode == 200) {
      debugPrint(response.toString());
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to start chat: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> updateName(
      String name, bool isRand) async {
    final url = Uri.parse('$_baseUrl/api/auth/${AppConstants.userId}');
    debugPrint("Laura: ${url.toString()}");

    var request = http.MultipartRequest("PUT", url)
      ..fields[isRand ? 'randname' : 'username'] = name;

    var streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      debugPrint("Laura: ${response.body}");
      isRand ? AppConstants.setRandname(name) : AppConstants.setUsername(name);
      debugPrint("New Name: ${AppConstants.username}");
      return jsonDecode(response.body);
    } else {
      debugPrint("Laura: ${response.body}");
      throw Exception('Failed to update name: ${response.statusCode}');
    }
  }

  static Future<String?> startUserChat(
      String userId, String otherUserId) async {
    final url = Uri.parse('$_baseUrl/api/chats/start-user-chat');

    try {
      // Create a multipart request
      var request = http.MultipartRequest('POST', url);

      // Add fields to the form data
      request.fields['userId'] = userId;
      request.fields['otherUserId'] = otherUserId;

      // Send the request and get the response
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // Parse the response
      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200 && responseData['success'] == true) {
        debugPrint("ChatID: ${responseData['chatId']}");
        return responseData['chatId'] as String;
      } else {
        // Failure case: print error and return null
        print('Failed to start user chat:');
        print('Response: $responseData');
        print('Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Error case: print error and return null
      print('Error starting user chat: $e');
      return null;
    }
  }

  static Future<void> completeTask(int id) async {
    print('habit id: $id');
    final url = Uri.parse(
        '$_baseUrl/api/tasks/$id/complete'); // Assuming endpoint structure

    try {
      // Create a multipart request
      var request = http.MultipartRequest('PUT', url);

      // Add userId to the form data
      request.fields['userId'] = AppConstants.userId ?? ''; // Handle null case

      // Send the request and get the response
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // Parse the response
      final responseData = jsonDecode(responseBody);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('Response: $responseData');
        return null;
      } else {
        // Failure case: print response and return null
        print('Failed to complete task:');
        print('Response: $responseData');
        print('Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Error case: print error and return null
      print('Error completing task: $e');
      // print('Response Body: ${responseData.toString()}'); // Print response body if available
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchDailyPosts(BuildContext context) async {
    // URL for the API endpoint
    final String url =
        'https://hearu-backend.onrender.com/api/tasks/daily/${AppConstants.userId}';

    try {
      // Make the GET request
      final response = await http.get(Uri.parse(url));

      // Parse the response body
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Check if the request was successful
      if (responseData['success'] == true) {
        // Return just the data part if successful
        return responseData['data'];
      } else {
        // Show error message in a snackbar if success is false
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  responseData['message'] ?? 'Failed to fetch daily posts'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }
    } catch (e) {
      // Handle network or parsing errors
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  static Future<Map<String, dynamic>> sendAnswer(
    String sessionId,
    String answer,
  ) async {
    final url = Uri.parse('$_baseUrl/api/mood/answer/$sessionId?isQuiz=false');
    final response = await http.post(url, body: {'answer': answer});

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send answer: ${response.statusCode}');
    }
  }
}
