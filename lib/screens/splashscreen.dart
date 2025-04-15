import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fyp/screens/login.dart';
import 'package:fyp/screens/virtual_guide.dart';
import 'package:fyp/screens/wrapper.dart';
import 'package:fyp/utils/colors.dart';

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {

  @override
  void initState() {
    super.initState();

    Timer(Duration(seconds: 3),(){
      Navigator.pushReplacement(
          context, MaterialPageRoute(
        builder: (context) => Wrapper(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: bg_dark,
        body: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 200,
              ),
              Image.asset(
                "asset/logo.png",
                height: 300,
                width: 300,
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "VoiceGrocery",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 35,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        )
    );
  }
}