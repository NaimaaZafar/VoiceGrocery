import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fyp/screens/login.dart';
import 'package:fyp/screens/signup.dart';
import 'package:fyp/screens/wrapper.dart';
import 'package:fyp/utils/colors.dart';
import 'package:lottie/lottie.dart';

class VirtualGuidescreen extends StatefulWidget {
  const VirtualGuidescreen({super.key});

  @override
  State<VirtualGuidescreen> createState() => _VirtualGuidescreenState();
}

class _VirtualGuidescreenState extends State<VirtualGuidescreen> {
  @override
  void initState() {
    super.initState();

    // Timer to navigate after 5 seconds
    Timer(const Duration(seconds: 05), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Wrapper()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg_dark,
      body: Center(
        child: LottieBuilder.asset(
          'asset/animation.json',
          height: 300, // Adjust height to fit the screen
          width: 300,  // Adjust width to fit the screen
          repeat: true, // Ensure the animation loops
        ),
      ),
    );
  }
}