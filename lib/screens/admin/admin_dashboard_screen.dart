import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_designs_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'admin_services_screen.dart';
import 'admin_shop_settings_screen.dart';
import 'admin_testimonials_screen.dart';
import 'admin_work_posts_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _card(context, Icons.calendar_month, 'Bookings', AppColors.primary,
              const AdminBookingsScreen()),
          _card(context, Icons.shopping_bag, 'Cone Orders', AppColors.accent,
              const AdminOrdersScreen()),
          _card(context, Icons.spa, 'Manage Products', AppColors.success,
              const AdminProductsScreen()),
          _card(context, Icons.brush, 'Manage Services', AppColors.pending,
              const AdminServicesScreen()),
          _card(context, Icons.palette, 'Manage Designs', AppColors.primaryDark,
              const AdminDesignsScreen()),
          _card(context, Icons.settings, 'Shop Settings', AppColors.textLight,
              const AdminShopSettingsScreen()),
          _card(context, Icons.reviews, 'Testimonials', AppColors.success,
              const AdminTestimonialsScreen()),
          _card(context, Icons.dynamic_feed, 'Our Work Feed', AppColors.accent,
              const AdminWorkPostsScreen()),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String label, Color color, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
