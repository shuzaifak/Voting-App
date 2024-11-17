import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:voting_system/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: 3000,
      splash: Center(
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: const Offset(0.0, 0.0),
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Curves.easeInOut,
            ),
          ),
          child: SizedBox(
            width: 300,
            height: 300,
            child: Image.asset(
              'assets/voting_logo.png',
            ),
          ),
        ),
      ),
      nextScreen: const LoginScreen(),
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: Colors.white,
    );
  }
}
