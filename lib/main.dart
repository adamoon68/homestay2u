import 'package:flutter/material.dart';

import 'screens/homestay_list_screen.dart';

void main() {
  runApp(const Homestay2UApp());
}

class Homestay2UApp extends StatelessWidget {
  const Homestay2UApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Homestay2U Malaysia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: const Color(0xFFF4F8F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const HomestayListScreen(),
    );
  }
}
