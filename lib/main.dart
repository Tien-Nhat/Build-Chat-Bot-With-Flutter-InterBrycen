import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:gptbrycen/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gptbrycen/tab_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF343541),
        appBarTheme: const AppBarTheme(color: Color(0xFF444654)),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection("memory")
              .doc("test1")
              .snapshots(),
          builder: (ctx, snapshot) {
            final document = snapshot.data;
            Map<String, dynamic>? data = document?.data();
            if (data?["test2"] == "true") {
              return const TabsScreen();
            }
            return const home_screen();
          }),
      builder: EasyLoading.init(),
    );
  }
}
