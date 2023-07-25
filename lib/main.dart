import 'package:betterclosetswap/pages/forgot_password.dart';
import 'package:betterclosetswap/pages/home.dart';
import 'package:betterclosetswap/pages/mobile.dart';
import 'package:betterclosetswap/pages/login_page.dart';
import 'package:betterclosetswap/pages/search.dart';
import 'package:betterclosetswap/pages/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClosetSwap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.amberAccent,
        hintColor: Colors.blueGrey,
      ),
      home: Home(),
    );
  }
}
