import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mental_health_app/screens/chat/chat.dart';
import 'package:mental_health_app/screens/community/community.dart';
import 'package:mental_health_app/screens/habit_tracker/habit_tracker.dart';
import 'package:mental_health_app/screens/store/store.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.black,
            indicatorColor: Colors.white.withOpacity(0.2),
            labelTextStyle: MaterialStateProperty.all(
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          child: NavigationBar(
            height: 75,
            elevation: 0,
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected:
                (index) => controller.selectedIndex.value = index,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.track_changes, size: 24, color: Colors.white),
                label: 'Habit Tracker',
              ),

              NavigationDestination(
                icon: Icon(
                  LucideIcons.message_square_code,
                  color: Colors.white,
                ),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.user, color: Colors.white),
                label: 'Community',
              ),
              NavigationDestination(
                icon: FaIcon(
                  FontAwesomeIcons.shop,
                  size: 18,
                  color: Colors.white,
                ),
                label: 'Store',
              ),
            ],
          ),
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    HabitTrackerScreen(),
    ChatScreen(),
    const CommunityScreen(),
    const StoreScreen(),
  ];
}
