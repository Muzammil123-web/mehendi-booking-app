import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shop_settings.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../utils/theme.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Wait briefly for Firebase auth stream to emit first state.
          return FutureBuilder(
            future: Future.delayed(const Duration(milliseconds: 800)),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _buildSplashContent();
              }
              if (!auth.isLoggedIn) {
                return const LoginScreen();
              }
              return auth.isAdmin ? const AdminDashboardScreen() : const HomeScreen();
            },
          );
        },
      ),
    );
  }

  Widget _buildSplashContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spa, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 20),
          FutureBuilder<ShopSettings>(
            future: FirestoreService().getShopSettings(),
            builder: (context, snapshot) {
              return Text(
                snapshot.data?.businessName ?? 'Mehendi Studio',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Book. Apply. Shine.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: Colors.white),
        ],
      ),
    );
  }
}
