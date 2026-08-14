import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/database.dart';
import 'core/services/database_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Show splash immediately while DB initialises
  runApp(const _LoadingApp());

  final db = await openDatabase();

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const SinosphereApp(),
    ),
  );
}

class _LoadingApp extends StatelessWidget {
  const _LoadingApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF020817),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('晨', style: TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w700)),
              SizedBox(height: 16),
              Text('Sinosphere',
                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 18, fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              SizedBox(height: 32),
              SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
