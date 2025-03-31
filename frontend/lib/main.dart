import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:mental_health_app/controllers/all_controller.dart';
import 'package:mental_health_app/navigation.dart';
import 'package:mental_health_app/screens/auth/login.dart';
import 'package:mental_health_app/screens/auth/signup.dart';
import 'package:mental_health_app/screens/mood.dart';
import 'package:mental_health_app/utils/theme.dart';
import 'constants.dart'; // Import the constants file
import 'package:get_storage/get_storage.dart'; // Import GetStorage
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(NavigationController());
  Get.put(AllController());
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Properly handle null case with a ternary operator
    Widget initialScreen = AppConstants.userId != null
        ? const MoodSelectionPage()
        : const LoginScreen();

    return GetMaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: MAppTheme.lightTheme,
      home: initialScreen,
    );
  }
}
