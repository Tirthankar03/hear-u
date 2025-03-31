import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mental_health_app/constants.dart';

class ApiService {
  static const String baseUrl = 'https://hearu-backend.onrender.com/api';

  Future<List<Map<String, dynamic>>> fetchPosts({
    required int page,
    required int limit,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/posts?sortBy=recent&userId=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        debugPrint(response.body);
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return (jsonResponse['data'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else {
          throw Exception(
            'API returned success: false - ${jsonResponse['message']}',
          );
        }
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching posts: $e');
      return [];
    }
  }

  Future<bool> upvotePost({required int postId, required String userId}) async {
    final url = Uri.parse('$baseUrl/posts/$postId/$userId/upvote');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to upvote post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error upvoting post: $e');
      return false;
    }
  }

  static Future<bool> updateUserDetails(
      String description, List<String> tags) async {
    final url = Uri.parse('$baseUrl/auth/${AppConstants.userId}');

    try {
      // Create a multipart request
      var request = http.MultipartRequest('PUT', url);

      // Add description as a field
      request.fields['description'] = description;

      // Add tags as a JSON-encoded string
      request.fields['tags'] = json.encode(
          tags); // Converts List<String> to JSON string like ["depressed", "lonely", "debt"]

      // Send the request
      final response = await request.send();

      // Get the response body
      final responseBody = await response.stream.bytesToString();
      debugPrint("User Details: ${responseBody.toString()}");
      debugPrint("User ID: ${AppConstants.userId}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(responseBody);
        debugPrint("PUT issue: ${jsonResponse.toString()}");
        return jsonResponse['success'] == true;
      } else {
        print('Failed to update user: ${response.statusCode} - $responseBody');
        return false;
      }
    } catch (e) {
      print('Error updating user details: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> findSimilarUsers(
      String userId, String sessionId) async {
    debugPrint("TalkCHat session Id: $sessionId");
    final url_prev =
        Uri.parse('$baseUrl/sessions/summarize-session/$sessionId');
    final response_prev = await http.post(url_prev);
    if (response_prev.statusCode == 200) {
      final Map<String, dynamic> jsonResponse_prev =
          json.decode(response_prev.body);
      if (!jsonResponse_prev['success']) {
        debugPrint("Error Prev api call: ${jsonResponse_prev.toString()}");
        return [];
      }
    }
    final url =
        Uri.parse('$baseUrl/sessions/find-similar-users/${userId}/$sessionId');
    // '$baseUrl/sessions/find-similar-users/675ev72npfr7wc3/9306ec39-ffe2-4f3e-b9b5-5f68a4615e76');

    try {
      final response = await http.get(url);
      // debugPrint("TalkCHat response: ${response.toString()}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['message'] == 'Similar users found') {
          List<dynamic> data = jsonResponse['data'];

          // Process the data and convert similarity to percentage
          List<Map<String, dynamic>> processedData = data.map((user) {
            return {
              'id': user['id'],
              'username': user['username'],
              'randname': user['randname'],
              'email': user['email'],
              'description': user['description'],
              'tags': List<String>.from(user['tags']),
              'ai_description': user['ai_description'],
              'similarity':
                  double.parse((user['similarity'] * 100).toStringAsFixed(2)),
            };
          }).toList();

          return processedData;
        } else {
          throw Exception('No similar users found in response');
        }
      } else {
        throw Exception('Failed to load similar users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching similar users: $e');
      return []; // Return empty list in case of error
    }
  }

  Future<List<Map<String, dynamic>>> fetchComments({
    required int postId,
    required int page,
    required int limit,
    required String sortBy,
    required String userId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/posts/$postId/comments?sortBy=$sortBy&userId=$userId',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return (jsonResponse['data'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
        } else {
          throw Exception(
            'API returned success: false - ${jsonResponse['message']}',
          );
        }
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> addComment({
    required int postId,
    required String userId,
    required String content,
  }) async {
    final url = Uri.parse('$baseUrl/posts/$postId/comment');
    try {
      final response = await http.post(
        url,
        body: {'userId': userId, 'content': content},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'];
        } else {
          throw Exception(
            'API returned success: false - ${jsonResponse['message']}',
          );
        }
      } else {
        throw Exception('Failed to add comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  Future<bool> upvoteComment({
    required int commentId,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/comments/$commentId/$userId/upvote');
    try {
      final response = await http.post(url);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to upvote comment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error upvoting comment: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> createPost({
    required String title,
    required String content,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/posts');
    try {
      final response = await http.post(
        url,
        body: {
          'title': title,
          'content': content,
          'userId': userId,
        }, // Send as form data (application/x-www-form-urlencoded)
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          return jsonResponse['data']['post'];
        } else {
          throw Exception(
            'API returned success: false - ${jsonResponse['message']}',
          );
        }
      } else {
        throw Exception('Failed to create post: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating post: $e');
      rethrow;
    }
  }
}
