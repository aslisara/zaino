import 'dart:async';
import 'package:flutter/material.dart';
import 'explore.dart';
import 'main.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _timer = Timer(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06141F),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniGlobe(size: 240, seconds: 8),
              const SizedBox(height: 28),
              const Text('Zaino',
                  style: TextStyle(
                      color: Colors.white, fontSize: 38, fontWeight: FontWeight.w700, letterSpacing: 4)),
              const SizedBox(height: 8),
              Text('Dünyayı sırtında taşı · Carry the world',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
