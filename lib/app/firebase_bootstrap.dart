import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../firebase_options.dart';
import 'app.dart';

class FirebaseBootstrap extends StatefulWidget {
  const FirebaseBootstrap({super.key});

  @override
  State<FirebaseBootstrap> createState() => _FirebaseBootstrapState();
}

class _FirebaseBootstrapState extends State<FirebaseBootstrap> {
  late Future<FirebaseApp> _initialization = _initialize();

  Future<FirebaseApp> _initialize() =>
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  void _retry() => setState(() => _initialization = _initialize());

  @override
  Widget build(BuildContext context) => FutureBuilder<FirebaseApp>(
    future: _initialization,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return const ProviderScope(child: BiteWiseApp());
      }

      return MaterialApp(
        title: 'BiteWise',
        debugShowCheckedModeBanner: false,
        theme: BiteWiseTheme.light(),
        home: Scaffold(
          body: snapshot.hasError
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: LoadErrorPanel(
                        title: 'BiteWise could not start',
                        message:
                            'Check your connection and app configuration, then try again.',
                        onRetry: _retry,
                      ),
                    ),
                  ),
                )
              : const ProfileDataLoadingView(photoAsset: AppAssets.honeyBee),
        ),
      );
    },
  );
}
