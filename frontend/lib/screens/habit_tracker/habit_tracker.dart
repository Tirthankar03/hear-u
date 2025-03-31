import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mental_health_app/api.dart';
import 'package:mental_health_app/screens/chat/chat_history.dart';
import 'package:mental_health_app/screens/habit_tracker/widgets/alarm_popup.dart';
import 'package:mental_health_app/screens/habit_tracker/widgets/articles.dart';
import 'package:mental_health_app/screens/habit_tracker/widgets/audio_player.dart';
import 'package:mental_health_app/screens/profile/profile.dart';
import 'package:mental_health_app/screens/quiz/quiz.dart';
import 'package:get_storage/get_storage.dart';

int score = 0;

class HabitTrackerScreen extends StatefulWidget {
  @override
  _HabitTrackerScreenState createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _leafAnimation;

  @override
  void initState() {
    super.initState();

    // Animation Controller for Leaves (wind effect)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _leafAnimation = Tween<double>(
      begin: -15,
      end: 15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glasses = _storage.read('glasses') ?? 0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  late int _glasses; // Tracks the number of glasses
  final int _maxGlasses = 8; // Maximum number of glasses
  final _storage = GetStorage(); // Instance of GetStorage

  // Function to increment glasses and score
  void _incrementGlasses() {
    setState(() {
      if (_glasses < _maxGlasses) {
        _glasses++; // Increment the glass count
        score += 100; // Increment global score by 100
        _storage.write("score", score);
        _storage.write('glasses', _glasses); // Store the updated value
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final api = Api();

// Then call the method on the instance
    final data = api.fetchDailyPosts(context);

    return Scaffold(
        body: FutureBuilder<Map<String, dynamic>?>(
            future: api.fetchDailyPosts(context),
            builder: (context, snapshot) {
              // Show loading spinner while waiting for data
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              // Show error message if fetch failed
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              // Show message if no data
              if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: Text('No data available'));
              }

              // Data is ready to use
              final data = snapshot.data!;

              return Stack(
                children: [
                  // Gradient Background
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF081423), // Dark blue night sky
                            Color(0xFF000000), // Deep black bottom
                          ],
                          stops: [0.3, 1], // Transition point
                        ),
                      ),
                    ),
                  ),

                  // Stars positioned only in the top part of the screen
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: screenHeight *
                        0.4, // Restrict stars to upper 40% of screen
                    child: Stack(
                      children: List.generate(
                        50,
                        (index) => Positioned(
                          top: Random().nextDouble() *
                              (screenHeight * 0.4), // Upper 40%
                          left: Random().nextDouble() * screenWidth,
                          child: BlinkingStar(),
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _leafAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: 20,
                        left: MediaQuery.of(context).size.width / 1.9 +
                            _leafAnimation.value,
                        child: Transform.rotate(
                          angle: 80,
                          child: Image.asset(
                            'assets/images/components/leaf.png',
                            fit: BoxFit.cover,
                            width: 210,
                            height: 220,
                          ),
                        ),
                      );
                    },
                  ),

                  // Scrollable Content
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 60, left: 20, right: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "My plan",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Get.to(() => ChatHistory());
                                        },
                                        child: Icon(
                                          Icons.chat_rounded,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 30,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Get.to(() => ProfilePage());
                                        },
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: 8),
                              Text(
                                "Mar 5",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                                strutStyle: StrutStyle(height: 1.5),
                              ),

                              SizedBox(height: 30),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 20,
                                  left: 20,
                                  right: 20,
                                ),
                                child: Text(
                                  "How's Your Mood",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: Text(
                                  "Check in with your mood\nIncrease emotional awareness by tracking your moods",
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => QuizScreen(),
                                        ),
                                      ),
                                      child: Text(
                                        "Mood Tracker",
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.purple,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  // First Container - Alarm Option
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF07233B),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.all(20),
                                      height: 190,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.alarm,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Set Alarm',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Expanded(
                                            child: SizedBox.expand(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  AlarmPopup.showAlarmPopup(
                                                      context);
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blueAccent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                child: Text(
                                                  'Configure',
                                                  style: TextStyle(
                                                      color: Colors.white
                                                          .withOpacity(0.8),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),

                                  // Second Container - Water Intake Tracker
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF07233B),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black26,
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(20),

                                      height: 190, // Ensuring equal height
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.water_drop,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Water Intake',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '$_glasses/$_maxGlasses glasses', // Display from stored value
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: SizedBox.expand(
                                              child: ElevatedButton(
                                                onPressed:
                                                    _incrementGlasses, // Call increment function
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blueAccent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      8,
                                                    ),
                                                  ),
                                                ),
                                                child: Text('Add Glass',
                                                    style: TextStyle(
                                                        color: Colors.white
                                                            .withOpacity(0.8),
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Morning section
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 20,
                                  left: 0,
                                  right: 20,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.wb_twilight,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Morning",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

// Use a collection-for to generate a list of widgets
                              ...List.generate(data["Morning"].length, (index) {
                                if (data["Morning"][index]["audio"] != null) {
                                  // If audio exists, return HabitCards
                                  return HabitCards(
                                    id: data["Morning"][index]["id"],
                                    category: data["Morning"][index]
                                        ["category"],
                                    isCompleted: data["Morning"][index]
                                        ["isCompleted"],
                                    text: data["Morning"][index]["audio"]
                                        ["title"],
                                    audioUrl: data["Morning"][index]["audio"]
                                        ["url"],
                                    durationMusic: data["Morning"][index]
                                                ["audio"]["duration"]
                                            .toString() ??
                                        "",
                                  );
                                } else if (data["Morning"][index]["article"] !=
                                    null) {
                                  // If article exists, return ArticlesCards
                                  return ArticlesCards(
                                    category: data["Morning"][index]
                                        ["category"],
                                    title: data["Morning"][index]["article"]
                                        ["title"],
                                    text: data["Morning"][index]["article"]
                                        ["content"],
                                    isCompleted: data["Morning"][index]
                                        ["isCompleted"],
                                    durationRead: data["Morning"][index]
                                            ["article"]["duration"] ??
                                        "",
                                    onCompletionChanged: (completed) {
                                      Api.completeTask(
                                        data["Morning"][index]["id"],
                                      );
                                      print(
                                          "Completion status changed to: $completed");
                                    },
                                  );
                                }
                                return SizedBox(); // Fallback if neither condition is met
                              }),

                              // HabitCards(
                              //   category: 'Breath',
                              //   isCompleted: false,
                              //   text: 'Help me survive this mf',
                              //   audioUrl:
                              //       'https://res.cloudinary.com/dlsh6g7cz/video/upload/v1741206310/audio_uploads/jb2bz29or7bvwxizwhdt.m4a',
                              //   durationMusic: 7,
                              // ),
                              // // articles
                              // ArticlesCards(
                              //   category: 'Articles',
                              //   title: '5 minutes helath tips',
                              //   text: 'vksejngkrtgnrkgnkgnrtkgnetkg ',
                              //   isCompleted: false,
                              //   durationRead: 8,
                              //   onCompletionChanged: (bool) {},
                              // ),

                              // Day Section
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 20,
                                  left: 0,
                                  right: 20,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.wb_sunny,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Day",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ...List.generate(data["Day"].length, (index) {
                                if (data["Day"][index]["audio"] != null) {
                                  // If audio exists, return HabitCards
                                  return HabitCards(
                                    id: data["Morning"][index]["id"],
                                    category: data["Day"][index]["category"],
                                    isCompleted: data["Day"][index]
                                        ["isCompleted"],
                                    text: data["Day"][index]["audio"]["title"],
                                    audioUrl: data["Day"][index]["audio"]
                                        ["url"],
                                    durationMusic: data["Day"][index]["audio"]
                                                ["duration"]
                                            .toString() ??
                                        "",
                                  );
                                } else if (data["Day"][index]["article"] !=
                                    null) {
                                  // If article exists, return ArticlesCards
                                  return ArticlesCards(
                                    category: data["Day"][index]["category"],
                                    title: data["Day"][index]["article"]
                                        ["title"],
                                    text: data["Day"][index]["article"]
                                        ["content"],
                                    isCompleted: data["Day"][index]
                                        ["isCompleted"],
                                    durationRead: data["Day"][index]["article"]
                                            ["duration"] ??
                                        "",
                                    onCompletionChanged: (completed) {
                                      Api.completeTask(
                                        data["Morning"][index]["id"],
                                      );
                                      print(
                                          "Completion status changed to: $completed");
                                    },
                                  );
                                }
                                return SizedBox(); // Fallback if neither condition is met
                              }),

                              // Evening Section
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 20,
                                  left: 0,
                                  right: 20,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.wb_sunny,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Evening",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              ...List.generate(data["Evening"].length, (index) {
                                if (data["Evening"][index]["audio"] != null) {
                                  // If audio exists, return HabitCards
                                  return HabitCards(
                                    id: data["Morning"][index]["id"],
                                    category: data["Evening"][index]
                                        ["category"],
                                    isCompleted: data["Evening"][index]
                                        ["isCompleted"],
                                    text: data["Evening"][index]["audio"]
                                        ["title"],
                                    audioUrl: data["Evening"][index]["audio"]
                                        ["url"],
                                    durationMusic: data["Evening"][index]
                                                ["audio"]["duration"]
                                            .toString() ??
                                        "",
                                  );
                                } else if (data["Evening"][index]["article"] !=
                                    null) {
                                  // If article exists, return ArticlesCards
                                  return ArticlesCards(
                                    category: data["Evening"][index]
                                        ["category"],
                                    title: data["Evening"][index]["article"]
                                        ["title"],
                                    text: data["Evening"][index]["article"]
                                        ["content"],
                                    isCompleted: data["Evening"][index]
                                        ["isCompleted"],
                                    durationRead: data["Evening"][index]
                                            ["article"]["duration"] ??
                                        "",
                                    onCompletionChanged: (completed) {
                                      Api.completeTask(
                                        data["Morning"][index]["id"],
                                      );
                                      print(
                                          "Completion status changed to: $completed");
                                    },
                                  );
                                }
                                return SizedBox(); // Fallback if neither condition is met
                              }),

                              // Evening
                              // Padding(
                              //   padding: const EdgeInsets.only(
                              //     top: 20,
                              //     left: 0,
                              //     right: 20,
                              //   ),
                              //   child: Row(
                              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //     children: [
                              //       Row(
                              //         children: [
                              //           Icon(
                              //             Icons.wb_cloudy_sharp,
                              //             color: Colors.grey,
                              //             size: 20,
                              //           ),
                              //           const SizedBox(width: 10),
                              //           Text(
                              //             "Evening",
                              //             style: TextStyle(
                              //               color: Colors.grey,
                              //               fontSize: 18,
                              //               fontWeight: FontWeight.bold,
                              //             ),
                              //           ),
                              //         ],
                              //       ),
                              //     ],
                              //   ),
                              // ),
                              // HabitCards(
                              //   habit: "Breath",
                              //   mood: "Anger",
                              //   exercise: "3 min meditation",
                              //   image: 'assets/images/components/anger.png',
                              // ),

                              // // articles
                              // ArticlesCards(),

                              // Padding(
                              //   padding: const EdgeInsets.only(
                              //     top: 20,
                              //     left: 0,
                              //     right: 20,
                              //   ),
                              //   child: Row(
                              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              //     children: [
                              //       Row(
                              //         children: [
                              //           Icon(
                              //             Icons.wb_cloudy_sharp,
                              //             color: Colors.grey,
                              //             size: 20,
                              //           ),
                              //           const SizedBox(width: 10),
                              //           Text(
                              //             "Night",
                              //             style: TextStyle(
                              //               color: Colors.grey,
                              //               fontSize: 18,
                              //               fontWeight: FontWeight.bold,
                              //             ),
                              //           ),
                              //         ],
                              //       ),
                              //     ],
                              //   ),
                              // ),
                              // HabitCards(
                              //   habit: "Breath",
                              //   mood: "Anger",
                              //   exercise: "3 min meditation",
                              //   image: 'assets/images/components/anger.png',
                              // ),

                              // // articles
                              // ArticlesCards(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }));
  }
}

class ArticlesCards extends StatefulWidget {
  const ArticlesCards({
    super.key,
    required this.category,
    required this.title,
    required this.text,
    required this.isCompleted,
    required this.durationRead,
    required this.onCompletionChanged,
  });

  final String category, text, title;
  final bool isCompleted;
  final String durationRead;
  final Function(bool) onCompletionChanged;

  @override
  _ArticlesCardsState createState() => _ArticlesCardsState();
}

class _ArticlesCardsState extends State<ArticlesCards> {
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    isChecked = widget.isCompleted;
  }

  void _showArticlePopup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color.fromARGB(255, 7, 35, 59),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.cancel, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.withOpacity(0.3)),
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        widget.text,
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        isChecked = true;
                      });
                      widget.onCompletionChanged(true);
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      "Complete",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final _storage = GetStorage();
    return Row(
      children: [
        CircularCheckbox(
          value: isChecked,
          onChanged: (bool? newValue) {
            setState(() {
              isChecked = newValue!;
              score += 100; // Increment global score by 100
              _storage.write("score", score);
            });
            widget.onCompletionChanged(newValue!);
          },
          activeColor: Colors.green,
          size: 30.0,
        ),
        Expanded(
          child: GestureDetector(
            onTap: _showArticlePopup,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 7, 35, 59),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.article, color: Colors.green, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            widget.category,
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (widget.isCompleted)
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CircularCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Color activeColor;
  final Color checkColor;
  final double size;

  const CircularCheckbox({
    Key? key,
    required this.value,
    required this.onChanged,
    this.activeColor = Colors.blue,
    this.checkColor = Colors.white,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onChanged(!value);
      },
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: value ? activeColor : Colors.transparent,
          border: Border.all(
            color: value ? activeColor : Colors.grey,
            width: 2.0,
          ),
        ),
        child: value
            ? Icon(
                Icons.check,
                color: checkColor,
                size: size * 0.6,
              )
            : null,
      ),
    );
  }
}

class HabitCards extends StatefulWidget {
  const HabitCards({
    super.key,
    required this.category,
    required this.isCompleted,
    required this.text,
    required this.audioUrl,
    required this.durationMusic,
    required this.id,
  });

  final String category, text, audioUrl, durationMusic;
  final bool isCompleted;
  final int id;

  @override
  _HabitCardsState createState() => _HabitCardsState();
}

class _HabitCardsState extends State<HabitCards> {
  bool isExpanded = false;
  bool isPlaying = false;
  final player = AudioPlayer();
  bool isChecked = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();

    // Listen to audio duration changes
    player.onDurationChanged.listen((newDuration) {
      debugPrint("Duration changed: ${newDuration.toString()}");
      setState(() {
        duration = newDuration;
      });
    });

    player.onPositionChanged.listen((newPosition) {
      debugPrint("Position changed: ${newPosition.toString()}");
      setState(() {
        position = newPosition;
      });
    });

    // Listen to player completion
    player.onPlayerComplete.listen((event) {
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final _storage = GetStorage();
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        CircularCheckbox(
          value: widget.isCompleted,
          onChanged: (bool? newValue) {
            setState(() {
              Api.completeTask(widget.id);
              isChecked = newValue!;
              score += 100; // Increment global score by 100
              _storage.write("score", score);
            });
          },
          activeColor: Colors.green,
          size: 30.0,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              debugPrint("Expanded");
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 7, 35, 59),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.air, color: Colors.blue, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                widget.category,
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.durationMusic,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (widget.isCompleted)
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                  if (isExpanded) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.blue,
                                ),
                                onPressed: () async {
                                  if (!isPlaying) {
                                    await player
                                        .play(UrlSource(widget.audioUrl));
                                    Duration? audioDuration =
                                        await player.getDuration();
                                    if (audioDuration != null) {
                                      setState(() {
                                        duration = audioDuration;
                                      });
                                    }
                                  } else {
                                    await player.pause();
                                  }
                                  setState(() {
                                    isPlaying = !isPlaying;
                                  });
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.replay, color: Colors.blue),
                                onPressed: () async {
                                  await player.stop();
                                  await player.play(UrlSource(widget.audioUrl));
                                  Duration? audioDuration =
                                      await player.getDuration();
                                  if (audioDuration != null) {
                                    setState(() {
                                      duration = audioDuration;
                                      isPlaying = true;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          // Progress bar and time indicators
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: Colors.blue,
                                    inactiveTrackColor: Colors.grey.shade800,
                                    thumbColor: Colors.blue,
                                    thumbShape: RoundSliderThumbShape(
                                        enabledThumbRadius: 6),
                                    overlayShape: RoundSliderOverlayShape(
                                        overlayRadius: 10),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    min: 0,
                                    max: duration.inSeconds.toDouble(),
                                    value: position.inSeconds.toDouble(),
                                    onChanged: (value) async {
                                      final position =
                                          Duration(seconds: value.toInt());
                                      await player.seek(position);
                                      if (!isPlaying) {
                                        await player.resume();
                                        setState(() {
                                          isPlaying = true;
                                        });
                                      }
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatTime(position),
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        formatTime(duration),
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Blinking Star Widget
class BlinkingStar extends StatefulWidget {
  @override
  _BlinkingStarState createState() => _BlinkingStarState();
}

class _BlinkingStarState extends State<BlinkingStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  final Random _random = Random();
  late double size;

  @override
  void initState() {
    super.initState();

    size = _random.nextDouble() * 3 + 2; // Star size between 2-5

    // Animation setup with random blinking duration
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _random.nextInt(2000) + 500),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white70.withOpacity(0.1),
                  blurRadius: 2,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
