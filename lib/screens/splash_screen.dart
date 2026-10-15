import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../widgets/common.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const AssetImage _splashImage = AssetImage(
    'assets/images/splash.png',
  );

  Timer? _timer;

  bool _imageReady = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_started) return;

    _started = true;

    _prepareSplash();
  }

  Future<void> _prepareSplash() async {
    try {
      // Load image before displaying splash content.
      await precacheImage(
        _splashImage,
        context,
      );
    } catch (_) {
      // Even if image loading fails,
      // navigation should continue.
    }

    if (!mounted) return;

    setState(() {
      _imageReady = true;
    });

    // Splash visible duration
    _timer = Timer(
      const Duration(milliseconds: 2200),
      _openGate,
    );
  }

  void _openGate() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(
          milliseconds: 450,
        ),
        reverseTransitionDuration: const Duration(
          milliseconds: 300,
        ),

        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return const Gate();
        },

        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        fit: StackFit.expand,
        children: [
          // ============================================
          // SPLASH BACKGROUND IMAGE
          // ============================================

          AnimatedOpacity(
            opacity: _imageReady ? 1 : 0,
            duration: const Duration(
              milliseconds: 350,
            ),
            child: const Image(
              image: _splashImage,
              fit: BoxFit.cover,

              // Center logo remains visible.
              alignment: Alignment.center,
            ),
          ),

          // ============================================
          // FALLBACK BACKGROUND
          // ============================================

          if (!_imageReady)
            const ColoredBox(
              color: Colors.black,
            ),

          // ============================================
          // BOTTOM DARK GRADIENT
          // ============================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 230,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                      Colors.black87,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ============================================
          // LOADER
          // ============================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 42,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 34,
                    height: 34,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: orange,
                      backgroundColor:
                          Color(0x33FFFFFF),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'LOADING...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}