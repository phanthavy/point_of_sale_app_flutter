import 'package:client/state/auth_store.dart';
import 'package:client/state/pos_store.dart';
import 'package:client/theme/app_colors.dart';
import 'package:client/views/home/home_screen.dart';
import 'package:client/views/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  posStore.attach(prefs);
  authStore.attach(prefs);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: AppColors.primary)),
      home: ListenableBuilder(
        listenable: authStore,
        builder: (context, _) {
          final user = authStore.user;
          if (user == null) return const LoginScreen();
          return HomeScreen(key: ValueKey(user.username), user: user);
        },
      ),
    );
  }
}
