import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mental_health_app/api.dart';
import 'package:mental_health_app/constants.dart';
import 'package:mental_health_app/screens/auth/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = "1W";
  List<FlSpot> _graphData = [];
  final _storage = GetStorage();
  var moodStr = "";
  late final emoji;

  @override
  void initState() {
    super.initState();
    _fetchGraphData();
    // _generateGraphData(_graphData);
    final i = _storage.read('selectedMood');
    final dict = getMood(i);
    moodStr = dict['label']!;
    emoji = dict['emoji']!;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _leafAnimation = Tween<double>(
      begin: -15,
      end: 15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    final storedData = _storage.read('moodData') as List<dynamic>?;
    if (storedData != null) {
      _graphData = storedData
          .map((e) => FlSpot(e['x'].toDouble(), e['y'].toDouble()))
          .toList();
    }
  }

  Future<void> _fetchGraphData() async {
    final id = _storage.read('userId');
    try {
      final response = await http.get(
          Uri.parse('https://hearu-backend.onrender.com/api/mood/history/$id'));
      print('hellloooo : ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _generateGraphData(data['assessments']);
        }
      } else {
        print('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void _generateGraphData(List<dynamic> assessments) {
    Map<String, double> moodMapping = {
      "very bad": 1,
      "bad": 2,
      "neutral": 3,
      "good": 4,
      "very good": 5,
    };

    List<FlSpot> graphData = assessments.map((assessment) {
      String mood = assessment["mood"];
      String timestamp = assessment["assessedAt"];

      // Convert UTC to IST
      DateTime utcTime = DateTime.parse(timestamp);
      DateTime istTime =
          utcTime.toLocal(); // Converts to device's local timezone

      double yValue = istTime.hour + (istTime.minute / 60.0); // Normalize time

      print(
          "IST Time: $istTime, Mood: $mood, X: $yValue, Y: ${moodMapping[mood]}");

      return FlSpot(yValue, moodMapping[mood]!);
    }).toList();
    print(graphData);
    setState(() {
      _graphData = graphData;
    });
  }

  late AnimationController _controller;
  late Animation<double> _leafAnimation;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Mood data: value, label, emoji
  final List<Map<String, dynamic>> _moods = [
    {'value': 1, 'label': 'Very Bad', 'emoji': '😢'},
    {'value': 2, 'label': 'Bad', 'emoji': '😞'},
    {'value': 3, 'label': 'Neutral', 'emoji': '😐'},
    {'value': 4, 'label': 'Good', 'emoji': '😊'},
    {'value': 5, 'label': 'Very Good', 'emoji': '😊👍'},
  ];

  Map<String, String> getMood(int value) {
    final mood = _moods.firstWhere(
      (mood) => mood['value'] == value,
      orElse: () => {'label': 'Unknown', 'emoji': '❓'},
    );
    return {'label': mood['label'], 'emoji': mood['emoji']};
  }

  // Function to add a plot point
  void addMoodPoint(double hour, double mood) {
    setState(() {
      // Ensure hour is between 0-23 and mood is between 1-5
      if (hour >= 0 && hour <= 23 && mood >= 1 && mood <= 5) {
        // Remove any existing point for this hour
        _graphData.removeWhere((spot) => spot.x == hour);
        // Add new point
        _graphData.add(FlSpot(hour, mood));
        // Sort by hour for proper line drawing
        _graphData.sort((a, b) => a.x.compareTo(b.x));
        // Store in GetStorage
        _storage.write(
          'moodData',
          _graphData.map((spot) => {'x': spot.x, 'y': spot.y}).toList(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
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
          // Stars in upper 40%
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.4,
            child: Stack(
              children: List.generate(
                50,
                (index) => Positioned(
                  top: _random.nextDouble() * (screenHeight * 0.4),
                  left: _random.nextDouble() * screenWidth,
                  child: const BlinkingStar(),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.12),
                CircleAvatar(
                  radius: screenWidth * 0.15, // Adjust size dynamically
                  backgroundImage:
                      const AssetImage('assets/images/components/anger.png'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppConstants.username ?? "",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              TextEditingController nameController =
                                  TextEditingController();
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.grey[300],
                                          child: IconButton(
                                            icon: Icon(Icons.close,
                                                size: 16, color: Colors.black),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      TextField(
                                        controller: nameController,
                                        decoration: InputDecoration(
                                          labelText: "Enter your name",
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue[800], // Dark blue
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () async {
                                            await Api.updateName(
                                                nameController.text, false);
                                            setState(() {});
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "Submit",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
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
                        },
                        icon: Icon(
                          Icons.edit,
                          color: Colors.white,
                        ))
                  ],
                ),
                Text(
                  AppConstants.email ?? "krishnabhdas3@gmail.com",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 25),
                Text(
                  AppConstants.description ?? "",
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 25),
                Wrap(
                  spacing: 6, // Space between chips horizontally
                  runSpacing: 6, // Space between chips vertically
                  children: (AppConstants.tags ?? [])
                      .map((tag) => Chip(
                            label: Text(
                              tag,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                            backgroundColor:
                                Colors.blue[900], // Matches your theme
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2), // Compact padding
                            materialTapTargetSize: MaterialTapTargetSize
                                .shrinkWrap, // Smaller tap area
                          ))
                      .toList(),
                ),
                const SizedBox(height: 25),

                // Mood Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ), // Add spacing between the containers
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 7, 35, 59),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Mood",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            CircleAvatar(
                              radius: screenWidth * 0.08,
                              backgroundColor: Colors.white,
                              child: Text(
                                emoji,
                                style: TextStyle(
                                  fontSize:
                                      screenWidth * 0.12, // Adjust emoji size
                                ),
                              ),
                            ),
                            Text(
                              moodStr,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 7, 35, 59),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Streaks",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amberAccent.withOpacity(
                                          0.8,
                                        ),
                                        spreadRadius: 4,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "7", // Replace with dynamic streak count
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.08,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withOpacity(0.3),
                                          offset: Offset(2, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                //Icon()
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = "1W";
                          _generateGraphData(_graphData);
                        });
                      },
                      child: Text(
                        "1W",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedFilter == "1W"
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = "1M";
                          _generateGraphData(_graphData);
                        });
                      },
                      child: Text(
                        "1M",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedFilter == "1M"
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 300,
                  width: screenWidth * 0.9,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        drawHorizontalLine: true,
                        horizontalInterval: 1,
                        verticalInterval:
                            4, // Every 4 hours for better visibility
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 40, // Space for mood labels
                            getTitlesWidget: (value, meta) {
                              switch (value.toInt()) {
                                case 1:
                                  return const Text(
                                    'Very Bad',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  );
                                case 2:
                                  return const Text(
                                    'Bad',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  );
                                case 3:
                                  return const Text(
                                    'Neutral',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  );
                                case 4:
                                  return const Text(
                                    'Good',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  );
                                case 5:
                                  return const Text(
                                    'Very Good',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  );
                                default:
                                  return const Text('');
                              }
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 4, // Show every 4th hour for readability
                            getTitlesWidget: (value, meta) {
                              final hour = value.toInt();
                              if (hour >= 0 && hour <= 23) {
                                return Text(
                                  'Hour $hour',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      minX: 0,
                      maxX: 23, // 24 segments (0-23)
                      minY: 1,
                      maxY: 5, // 5 segments (1-5)
                      lineBarsData: [
                        LineChartBarData(
                          spots: _graphData,
                          isCurved: false,
                          curveSmoothness: 0.5,
                          color: Colors.blue,
                          barWidth: 1,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.withOpacity(0.3),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(
                              radius: 2,
                              color: Colors.blue,
                              strokeWidth: 1,
                              strokeColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.2,
                      vertical: 15,
                    ),
                  ),
                  onPressed: () {
                    AppConstants.clear();
                    Get.offAll(LoginScreen());
                  },
                  child: Text(
                    "Log Out",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9)),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MoodChartPage extends StatelessWidget {
  const MoodChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Chart')),
      body: Column(
        children: [
          const ProfilePage(),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Example: Add a mood point (e.g., Hour 10, Mood 3)
              final chartState =
                  context.findAncestorStateOfType<_ProfilePageState>();
              chartState?.addMoodPoint(
                10,
                3,
              ); // Replace with dynamic values as needed
            },
            child: const Text('Add Mood (Hour 10, Neutral)'),
          ),
        ],
      ),
    );
  }
}

class BlinkingStar extends StatefulWidget {
  const BlinkingStar({super.key});

  @override
  _BlinkingStarState createState() => _BlinkingStarState();
}

class _BlinkingStarState extends State<BlinkingStar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late double size;

  @override
  void initState() {
    super.initState();
    size = _random.nextDouble() * 3 + 2;
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

// Global random instance to prevent hot reload issues
final Random _random = Random();
