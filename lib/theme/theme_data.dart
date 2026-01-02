import 'package:flutter/material.dart';

ThemeData getApplicationTheme() {
  return ThemeData(
    useMaterial3: false,

    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),

    primarySwatch: Colors.orange,
    scaffoldBackgroundColor: Colors.grey,
    fontFamily: 'OpenSans-Italic',
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontFamily: 'OpenSans-Regular',
        ),
        backgroundColor: const Color(0xFF5B16D0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF524632),
      selectedItemColor: Color(0xFFA48256),
      unselectedItemColor: Color(0xFF8E8E8E),
      selectedIconTheme: IconThemeData(color: Color(0xFFA48256)),
      unselectedIconTheme: IconThemeData(color: Colors.white),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'OpenSans-Regular',
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: 'OpenSans-Regular',
      ),
    ),
  );
}
