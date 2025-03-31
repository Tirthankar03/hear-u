import 'package:get_storage/get_storage.dart';

class AppConstants {
  static final GetStorage _storage = GetStorage();

  // Getter methods to access the values, explicitly allowing null
  static String? get username => _storage.read('username');
  static String? get randname => _storage.read('randname');
  static String? get userId => _storage.read('userId');
  static String? get description => _storage.read('description');
  static String? get email => _storage.read('email');
  static List<dynamic>? get tags =>
      _storage.read('tags')?.cast<String>(); // Getter for tags

  // Setter methods
  static void setUsername(String? value) => _storage.write('username', value);
  static void setRandname(String? value) => _storage.write('randname', value);
  static void setUserId(String? value) => _storage.write('userId', value);
  static void setEmail(String? value) => _storage.write('email', value);
  static void setDescription(String? value) =>
      _storage.write('description', value);
  static void setTags(List<dynamic>? value) =>
      _storage.write('tags', value); // Setter for tags

  // Clear all stored values
  static void clear() {
    _storage.remove('username');
    _storage.remove('randname');
    _storage.remove('userId');
    _storage.remove('description');
    _storage.remove('email');
    _storage.remove('tags'); // Clear tags as well
  }
}
