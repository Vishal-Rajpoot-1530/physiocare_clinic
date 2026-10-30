import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:physiocare_clinic/screens/splash_screen.dart';

import 'db/app_db.dart';
import 'screens/auth.dart';
import 'screens/shell.dart';
import 'screens/subscription_expired.dart';
import 'widgets/common.dart';

Future<void> loadPlans() async {
  final plans = await AppDb.i.plans();
  await AppDb.i.setPlans(plans);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const PowerCave());
}

class PowerCave extends StatelessWidget {
  const PowerCave({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Updated branding
      title: 'r',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: orange,
          brightness: Brightness.light,
          primary: orange,
        ).copyWith(onSurface: ink, onSurfaceVariant: muted),
        scaffoldBackgroundColor: night,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
        iconTheme: const IconThemeData(color: ink),
        appBarTheme: const AppBarTheme(
          backgroundColor: night,
          foregroundColor: ink,
          surfaceTintColor: Colors.transparent,
        ),
        fontFamily: 'Roboto',
      ),

      // Phone-style layout on desktop/tablet
      builder: (context, child) {
        return ColoredBox(
          color: night,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },

      // IMPORTANT:
      // App starts from Splash, NOT Gate.
      home: const SplashScreen(),
    );
  }
}

///
/// Decides where user should go after Splash:
///
/// Session exists -> Dashboard
/// No session     -> Login
///
class Gate extends StatefulWidget {
  const Gate({super.key});

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  bool? hasSession;
  bool subscriptionExpired = false;
  bool checkingSession = false;
  Object? checkError;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    if (checkingSession) return;
    setState(() {
      checkingSession = true;
      checkError = null;
      hasSession = null;
      subscriptionExpired = false;
    });

    var session = false;
    try {
      session = await AppDb.i.hasSession();
      if (!session) {
        if (mounted) setState(() => hasSession = false);
        return;
      }

      final mode = await AppDb.i.accountMode;
      final admin = mode == AccountMode.online
          ? await AppDb.i.currentAdmin()
          : null;
      final expired =
          mode == AccountMode.online && admin?['subscription_active'] != true;

      if (!mounted) return;

      setState(() {
        hasSession = !expired;
        subscriptionExpired = expired;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        hasSession = null;
        subscriptionExpired = false;
        checkError = error;
      });
    } finally {
      if (mounted) {
        setState(() {
          checkingSession = false;
        });
      }
    }
  }

  Widget _checkErrorView() {
    return Scaffold(
      backgroundColor: night,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, color: warnRed, size: 44),
              const SizedBox(height: 14),
              const Text(
                'Unable to verify your clinic subscription',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$checkError\nPlease check your connection and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted, height: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: checkingSession ? null : _checkSession,
                icon: checkingSession
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(checkingSession ? 'Checking...' : 'Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (checkError != null) {
      return _checkErrorView();
    }

    if (hasSession == null) {
      return const Scaffold(
        backgroundColor: night,
        body: Center(child: CircularProgressIndicator(color: orange)),
      );
    }

    if (hasSession!) {
      return const Shell();
    }

    if (subscriptionExpired) {
      return const SubscriptionExpiredScreen();
    }

    return const AuthScreen();
  }
}
