import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmPopup {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> _initializeNotifications() async {
    try {
      tz.initializeTimeZones();
      final kolkataTimeZone = tz.getLocation('Asia/Kolkata');
      tz.setLocalLocation(kolkataTimeZone);

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      bool? initialized =
          await _notificationsPlugin.initialize(initializationSettings);
      debugPrint('Notifications initialized: $initialized');

      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        bool? areEnabled = await androidPlugin.areNotificationsEnabled();
        debugPrint('Notifications enabled: $areEnabled');
        if (areEnabled == false) {
          bool? granted = await androidPlugin.requestNotificationsPermission();
          debugPrint('Permission granted: $granted');
        }
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  static Future<void> _showNotification() async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'alarm_channel',
        'Alarm Notifications',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound('alarm'),
        ongoing: true,
        autoCancel: false,
      );
      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        0,
        'Alarm',
        'Your alarm is ringing!',
        notificationDetails,
      );
      debugPrint('Notification shown successfully');
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  static Future<void> _scheduleAlarm(
      BuildContext context, DateTime scheduledTime) async {
    final now = DateTime.now();
    final duration = scheduledTime.difference(now);
    debugPrint('Scheduling alarm for: $scheduledTime, duration: $duration');
    Future.delayed(duration, () async {
      try {
        await _audioPlayer.play(AssetSource('mp3/alarm.mp3'));
        await _showNotification();
        _showAlarmDialog(
            context, scheduledTime); // Reopen popup when alarm triggers
      } catch (e) {
        debugPrint('Error playing alarm or showing notification: $e');
      }
    });
  }

  static void _showAlarmDialog(BuildContext context, DateTime scheduledTime) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing by tapping outside
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF07233B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alarm, color: Colors.white, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'Alarm Ringing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Set for ${TimeOfDay.fromDateTime(scheduledTime).format(context)}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () async {
                              await _audioPlayer.stop();
                              await _notificationsPlugin.cancel(0);
                              await Future.delayed(Duration(minutes: 5));
                              await _audioPlayer
                                  .play(AssetSource('mp3/alarm.mp3'));
                              await _showNotification();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                            child: Text('Snooze 5 min'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          child: ElevatedButton(
                            onPressed: () async {
                              await _audioPlayer.stop();
                              await _notificationsPlugin.cancel(0);
                              Navigator.pop(
                                  context); // Close dialog only on Stop
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: Text('Stop Alarm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void showAlarmPopup(BuildContext context) {
    DateTime? selectedTime;
    bool isAlarmSet = false;

    _initializeNotifications();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFF07233B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alarm, color: Colors.white, size: 40),
                    SizedBox(height: 12),
                    Text(
                      'Set Alarm',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          final now = DateTime.now();
                          selectedTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            picked.hour,
                            picked.minute,
                          );
                          if (selectedTime!.isBefore(now)) {
                            selectedTime = selectedTime!.add(Duration(days: 1));
                          }
                          setState(() {
                            isAlarmSet = true;
                          });
                          await _scheduleAlarm(context, selectedTime!);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        selectedTime == null
                            ? 'Set Time'
                            : 'Set for ${TimeOfDay.fromDateTime(selectedTime!).format(context)}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isAlarmSet) ...[
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Flexible(
                            child: ElevatedButton(
                              onPressed: () async {
                                await _audioPlayer
                                    .play(AssetSource('mp3/alarm.mp3'));
                                await _showNotification();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: Text('Test Alarm',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          SizedBox(width: 10),
                          Flexible(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey,
                              ),
                              child: Text('Close',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) async {
      if (isAlarmSet && selectedTime != null) {
        final now = DateTime.now();
        if (selectedTime!.isAfter(now)) {
          await _scheduleAlarm(context, selectedTime!);
        }
      }
    });
  }
}
