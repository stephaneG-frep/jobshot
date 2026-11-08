import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_scaffold.dart';
import 'onboarding_screen.dart';
import '../app.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboarded = prefs.getBool('onboarded') ?? false;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => onboarded ? const MainScaffold() : const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
                : const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt, size: 48, color: Colors.white),
              ).animate().scale(duration: 700.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                'JobShot',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Capturez vos candidatures',
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : AppTheme.textSecondary,
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}
