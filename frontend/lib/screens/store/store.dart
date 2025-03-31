import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mental_health_app/constants.dart';
import 'package:mental_health_app/screens/habit_tracker/habit_tracker.dart';

class BlinkingStar extends StatelessWidget {
  const BlinkingStar({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star,
      color: Colors.white,
      size: 4 + Random().nextDouble() * 4,
    );
  }
}

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final Random _random = Random();
  final _storage = GetStorage();
  int userPoints = 0;
  final int maxPoints = 3000;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    userPoints = _storage.read("score") ?? 0;
  }

  final List<Map<String, dynamic>> storeItems = [
    {
      "title": "Relaxing Meditation",
      "type": "Music",
      "cost": 1000,
      "icon": Icons.music_note,
    },
    {
      "title": "Deep Focus Beats",
      "type": "Music",
      "cost": 1500,
      "icon": Icons.library_music,
    },
    {
      "title": "Mindfulness Guide",
      "type": "Article",
      "cost": 1200,
      "icon": Icons.article,
    },
    {
      "title": "Better Sleep Tips",
      "type": "Article",
      "cost": 1800,
      "icon": Icons.menu_book,
    },
  ];

  void _redeemItem(int cost) {
    if (userPoints >= cost) {
      setState(() {
        userPoints -= cost;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Item unlocked successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Not enough points!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = userPoints / maxPoints;
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Store",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.white),
        //   onPressed: () {
        //     if (Navigator.canPop(context)) {
        //       Navigator.pop(context);
        //     }
        //   },
        // ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF081423), Color(0xFF000000)],
                  stops: [0.3, 1],
                ),
              ),
            ),
          ),
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
          SafeArea(
            child: Scaffold(
              body: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "Hey,",
                              style: TextStyle(
                                fontSize: 26,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              AppConstants.username ?? "",
                              style: TextStyle(
                                fontSize: 26,
                                color: Colors.blue.shade300,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade900,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade800.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$userPoints pts',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blueAccent),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Next Reward: Meditation Music',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.shade800,
                                  color: Colors.blueAccent,
                                  minHeight: 10,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Unlock Rewards",
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.5, // Constrain height
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: storeItems.length,
                        itemBuilder: (context, index) {
                          final item = storeItems[index];
                          final bool canUnlock = userPoints >= item["cost"];

                          return GestureDetector(
                            onTap: () => _redeemItem(item["cost"]),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 7, 35, 59),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item["icon"],
                                    size: 40,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    item["title"],
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "${item["cost"]} pts",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: canUnlock
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: canUnlock
                                        ? () => _redeemItem(item["cost"])
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canUnlock
                                          ? Colors.black87
                                          : Colors.grey,
                                      disabledForegroundColor:
                                          Colors.white.withOpacity(0.5),
                                    ),
                                    child: const Text(
                                      "Unlock",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
