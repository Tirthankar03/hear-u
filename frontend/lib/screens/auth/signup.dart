import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mental_health_app/api.dart';
import 'dart:math';
import 'package:mental_health_app/navigation.dart';
import 'package:mental_health_app/screens/auth/login.dart';
import 'package:mental_health_app/screens/auth/user_details.dart';

// BlinkingStar widget (assuming it's defined elsewhere, included here for completeness)
class BlinkingStar extends StatelessWidget {
  const BlinkingStar({super.key});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star, color: Colors.white, size: 5);
  }
}

// FallingStar widget (assuming it's defined elsewhere, included here for completeness)
class FallingStar extends StatelessWidget {
  final double startLeft;

  const FallingStar({required this.startLeft, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(); // Placeholder, replace with actual implementation
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController name = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController email = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    password.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Stack(
        children: [
          // Background Gradient
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

          // Stars positioned only in the top part of the screen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.4,
            child: SizedBox.expand(
              child: Stack(
                children: List.generate(
                  50,
                  (index) => Positioned(
                    top: Random().nextDouble() * (screenHeight * 0.4),
                    left: Random().nextDouble() * screenWidth,
                    child: const BlinkingStar(),
                  ),
                ),
              ),
            ),
          ),

          // Falling Stars
          Positioned.fill(
            child: Stack(
              children: List.generate(
                3,
                (index) =>
                    FallingStar(startLeft: Random().nextDouble() * screenWidth),
              ),
            ),
          ),

          // Signup Form
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Join us on your journey to better mental health",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: name,
                      decoration: InputDecoration(
                        hintText: "Full Name",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: email,
                      decoration: InputDecoration(
                        hintText: "Email",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      obscureText: true,
                      controller: password,
                      decoration: InputDecoration(
                        hintText: "Password",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          bool success = await Api().signup(
                            context,
                            name.text,
                            password.text,
                            email.text,
                          );
                          if (success) {
                            Get.to(() => const UserDetails());
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "or",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.to(() => const LoginScreen());
                      },
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
