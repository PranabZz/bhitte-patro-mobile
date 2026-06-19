import 'package:flutter/material.dart';
import 'custom_bottom_nav.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final int index;

  const MainLayout({super.key, required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: child,
        bottomNavigationBar: CustomBottomNav(currentIndex: index),
      ),
    );
  }
}
