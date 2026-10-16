import 'package:flutter/material.dart';

import 'pages/history_page.dart';
import 'pages/main_navigation_page.dart';
import 'pages/menu_detail_page.dart';
import 'pages/menu_list_page.dart';
import 'pages/order_page.dart';
import 'pages/profile_page.dart';
import 'services/local_db_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await LocalDbService.instance.init();
    await ThemeService.instance.init();
  } catch (e) {
    debugPrint('Initialization warning: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final primaryColor = ThemeService.instance.primaryColor;
        final themeMode = ThemeService.instance.themeMode;

        return MaterialApp(
          title: 'Kantin Bu Sari',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          // Tema Terang (Light Mode)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              brightness: Brightness.light,
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF9FAFB),
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 1,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
            ),
          ),
          // Tema Gelap (Dark Mode)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              primary: primaryColor,
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E1E),
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardTheme: const CardThemeData(
              color: Color(0xFF1E1E1E),
              elevation: 2,
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              backgroundColor: Color(0xFF1E1E1E),
            ),
          ),

          // Daftarkan semua route aplikasi Kantin Bu Sari
          initialRoute: '/',
          routes: {
            '/': (context) => const MainNavigationPage(),
            '/menu': (context) => const MenuListPage(),
            '/detail': (context) => const MenuDetailPage(),
            '/pesan': (context) => const OrderPage(),
            '/riwayat': (context) => const HistoryPage(),
            '/profil': (context) => const ProfilePage(),
          },
        );
      },
    );
  }
}
