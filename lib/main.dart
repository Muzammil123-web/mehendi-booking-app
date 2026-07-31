import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/theme.dart';

// Must be a top-level function: handles a push notification arriving while
// the app is fully closed/backgrounded. We don't need to do anything extra
// here since FCM shows the system notification automatically — this just
// satisfies the plugin's setup requirement.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MehendiApp());
}

class MehendiApp extends StatelessWidget {
  const MehendiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'Mehendi Studio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        builder: (context, child) {
          // The whole app was designed mobile-first. Rather than a full
          // separate desktop layout, on wide screens (web/tablet/desktop)
          // we constrain content to a phone-like column and center it —
          // keeps every screen usable and good-looking without a rewrite.
          final width = MediaQuery.of(context).size.width;
          if (width <= 600 || child == null) return child ?? const SizedBox();
          return Container(
            color: AppColors.primaryDark,
            child: Center(
              child: Container(
                width: 480,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}
