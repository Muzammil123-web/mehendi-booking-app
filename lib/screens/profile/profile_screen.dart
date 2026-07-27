import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../models/shop_settings.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../orders/my_orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _openInstagram(String handle) async {
    final appUri = Uri.parse('instagram://user?username=$handle');
    final webUri = Uri.parse('https://instagram.com/$handle');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.appUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                              fontSize: 32, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(user.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(user.email, style: const TextStyle(color: AppColors.textLight)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _tile(Icons.phone_outlined, 'Phone', user.phone),
                _tile(Icons.location_on_outlined, 'Address', user.address ?? 'Not set'),
                const SizedBox(height: 20),
                StreamBuilder<ShopSettings>(
                  stream: FirestoreService().streamShopSettings(),
                  builder: (context, snapshot) {
                    final settings = snapshot.data;
                    final handle = settings?.instagramHandle ?? '';
                    final phone = settings?.phoneNumber ?? '';
                    final email = settings?.contactEmail ?? '';
                    if (handle.isEmpty && phone.isEmpty && email.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        if (handle.isNotEmpty)
                          GestureDetector(
                            onTap: () => _openInstagram(handle),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFFD1D1D)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.camera_alt, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'See more of our work — follow @$handle on Instagram',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ),
                        if (phone.isNotEmpty || email.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (phone.isNotEmpty)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                                    icon: const Icon(Icons.call, size: 16, color: AppColors.primary),
                                    label: const Text('Call Us',
                                        style: TextStyle(color: AppColors.primary, fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              if (phone.isNotEmpty && email.isNotEmpty) const SizedBox(width: 10),
                              if (email.isNotEmpty)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => launchUrl(Uri.parse(
                                        'mailto:$email?subject=${Uri.encodeComponent('Mehendi Booking Enquiry')}')),
                                    icon: const Icon(Icons.email_outlined,
                                        size: 16, color: AppColors.primary),
                                    label: const Text('Email Us',
                                        style: TextStyle(color: AppColors.primary, fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
                  title: const Text('My Orders'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
                ),
                if (auth.isAdmin)
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined,
                        color: AppColors.primary),
                    title: const Text('Admin Dashboard'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                  ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text('Logout', style: TextStyle(color: AppColors.error)),
                  onTap: () async {
                    await auth.signOut();
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
    );
  }

  Widget _tile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textLight, size: 20),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(color: AppColors.textLight)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
