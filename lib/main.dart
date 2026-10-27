import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Blood4UBootstrap());
}

class Blood4UBootstrap extends StatefulWidget {
  const Blood4UBootstrap({super.key});

  @override
  State<Blood4UBootstrap> createState() => _Blood4UBootstrapState();
}

class _Blood4UBootstrapState extends State<Blood4UBootstrap> {
  late final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            title: 'Blood4U',
            theme: lightTheme,
            home: const _StartupMessage(
              title: 'Blood4U could not connect',
              message:
                  'Check the Firebase app configuration, then restart the app.',
            ),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            title: 'Blood4U',
            theme: lightTheme,
            home: const _StartupMessage(
              title: 'Blood4U',
              message: 'Starting securely…',
              showProgress: true,
            ),
          );
        }
        return const Blood4UApp();
      },
    );
  }
}

class Blood4UApp extends StatelessWidget {
  const Blood4UApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood4U',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _StartupMessage(
            title: 'Blood4U',
            message: 'Checking your sign-in…',
            showProgress: true,
          );
        }
        if (snapshot.hasError) {
          return const _StartupMessage(
            title: 'Unable to check sign-in',
            message: 'Please close and reopen the app.',
          );
        }
        return snapshot.data == null ? const LoginScreen() : const HomeScreen();
      },
    );
  }
}

class _StartupMessage extends StatelessWidget {
  const _StartupMessage({
    required this.title,
    required this.message,
    this.showProgress = false,
  });

  final String title;
  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.volunteer_activism, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (showProgress) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
