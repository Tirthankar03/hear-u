import 'package:flutter/material.dart';

class MAppTheme {
  MAppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Urbanist',
    disabledColor: Colors.grey,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.transparent,
  );

  static BoxDecoration gradientBackground = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color.fromARGB(255, 17, 44, 76), Color(0xFF000000)],
    ),
  );
}
