import 'package:flutter/material.dart';
import '../../models/shop_settings.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class AdminShopSettingsScreen extends StatefulWidget {
  const AdminShopSettingsScreen({super.key});

  @override
  State<AdminShopSettingsScreen> createState() => _AdminShopSettingsScreenState();
}

class _AdminShopSettingsScreenState extends State<AdminShopSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _businessNameCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _firestoreService.getShopSettings();
    setState(() {
      _businessNameCtrl.text = settings.businessName;
      _upiCtrl.text = settings.upiId;
      _instagramCtrl.text = settings.instagramHandle;
      _phoneCtrl.text = settings.phoneNumber;
      _emailCtrl.text = settings.contactEmail;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _firestoreService.updateShopSettings(ShopSettings(
      upiId: _upiCtrl.text.trim(),
      businessName: _businessNameCtrl.text.trim(),
      instagramHandle: _instagramCtrl.text.trim().replaceAll('@', ''),
      phoneNumber: _phoneCtrl.text.trim(),
      contactEmail: _emailCtrl.text.trim(),
    ));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Shop settings saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _businessNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Business Name',
                    helperText: 'Shown on the splash screen and headers throughout the app',
                  ),
                ),
                const SizedBox(height: 24),
                const Text('UPI Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'Customers can pay you directly via PhonePe, Google Pay, Paytm, or any UPI app using this ID.',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _upiCtrl,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID',
                    hintText: 'yourname@okhdfcbank / yourname@ybl',
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Contact Info', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'Shown as Call and Email buttons for customers on the Profile tab.',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+91 98765 43210',
                    prefixIcon: Icon(Icons.call_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Contact Email',
                    hintText: 'yourshop@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Social', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'Adds a "Follow us on Instagram" button on the Profile tab so customers can see your reels and past work.',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _instagramCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Instagram Username',
                    hintText: 'yourshopname (without the @)',
                    prefixIcon: Icon(Icons.camera_alt_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _save, child: const Text('Save Settings')),
              ],
            ),
    );
  }
}
