import 'package:get/state_manager.dart';

class AllController extends GetxController {
  final moodSubmit = false.obs;

  void toggleModdSubmit() {
    moodSubmit.value = !moodSubmit.value;
  }
}
