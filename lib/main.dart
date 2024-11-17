import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:voting_system/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voting System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class AppColors {
  static const Color primaryBlue = Color(0xFF2962FF);
  static const Color textFieldBorder = Color(0xFFE0E0E0);
  static const Color hintText = Color(0xFFBDBDBD);
}

class CustomTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const CustomTextField({
    Key? key,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    required this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
