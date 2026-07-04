import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/brew_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CoffeeRecordApp());
}

class CoffeeRecordApp extends StatelessWidget {
  const CoffeeRecordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BrewProvider()..loadRecords(),
      child: MaterialApp(
        title: '手冲咖啡记录',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.brown,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
