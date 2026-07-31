import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/booking.dart'; // shared PaymentMethod/PaymentStatus enums
import '../../models/order.dart'; // also exports CartItemData
import '../../models/shop_settings.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../home/home_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  PaymentMethod _paymentMethod = PaymentMethod.cod;
  bool _isProcessing = false;
  ShopSettings? _shopSettings;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().appUser;
    if (user?.address != null) _addressCtrl.text = user!.address!;
    _firestoreService.getShopSettings().then((s) {
      if (mounted) setState(() => _shopSettings = s);
    });
  }

  double _deliveryFee(double subtotal) {
    if (subtotal >= AppConstants.freeDeliveryAboveAmount) return 0;
    return AppConstants.deliveryFeeFlat;
  }

  Future<void> _placeOrder() async {
    final user = context.read<AuthProvider>().appUser;
    final cart = context.read<CartProvider>();
    if (user == null || cart.isEmpty) return;

    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a delivery address — yours, or whoever this is for')));
      return;
    }

    setState(() => _isProcessing = true);

    final subtotal = cart.subtotal;
    final deliveryFee = _deliveryFee(subtotal);
    final total = subtotal + deliveryFee;

    final order = OrderModel(
      id: '',
      userId: user.uid,
      userName: user.name,
      userPhone: user.phone,
      deliveryAddress: _addressCtrl.text.trim(),
      items: cart.itemList
          .map((i) => CartItemData(
                productId: i.product.id,
                name: i.product.name,
                price: i.product.price,
                quantity: i.quantity,
                imageUrl: i.product.imageUrl,
              ))
          .toList(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      paymentMethod: _paymentMethod,
      createdAt: DateTime.now(),
    );

    if (_paymentMethod == PaymentMethod.cod) {
      try {
        await _firestoreService.createOrder(order);
        cart.clearCart();
        if (!mounted) return;
        _showSuccessAndExit();
      } catch (e) {
        _showError('Could not place order. Please try again.');
      }
      return;
    }

    // UPI
    final upiId = _shopSettings?.upiId ?? '';
    if (upiId.isEmpty) {
      _showError('UPI payment isn\'t set up yet — please choose Cash on Delivery.');
      return;
    }
    try {
      await _firestoreService.createOrder(order);
      final uri = Uri.parse(
        'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(_shopSettings?.businessName ?? 'Mehendi Studio')}'
        '&am=${total.toStringAsFixed(2)}&cu=INR'
        '&tn=${Uri.encodeComponent('Henna cone order')}',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      cart.clearCart();
      if (!mounted) return;
      _showSuccessAndExit();
    } catch (e) {
      _showError('Could not open your UPI app. Please try again.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
  }

  void _showSuccessAndExit() {
    setState(() => _isProcessing = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 56),
            const SizedBox(height: 16),
            const Text('Order Placed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text(
              'Your henna cones are being packed. You can track the order in My Orders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final deliveryFee = _deliveryFee(cart.subtotal);
    final total = cart.subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Ordering for someone else? Just type their address below.',
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'House no, street, city, pincode',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: Column(
                children: [
                  ...cart.itemList.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text('${item.product.name} x${item.quantity}',
                                    style: const TextStyle(fontSize: 13))),
                            Text(
                                '${AppConstants.currencySymbol}${item.totalPrice.toStringAsFixed(0)}'),
                          ],
                        ),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: AppColors.textLight)),
                      Text('${AppConstants.currencySymbol}${cart.subtotal.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Fee', style: TextStyle(color: AppColors.textLight)),
                      Text(deliveryFee == 0
                          ? 'FREE'
                          : '${AppConstants.currencySymbol}${deliveryFee.toStringAsFixed(0)}'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${AppConstants.currencySymbol}${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_shopSettings?.upiId.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _paymentOption(
                  method: PaymentMethod.upi,
                  icon: Icons.qr_code,
                  title: 'PhonePe / UPI',
                  subtitle: 'Pay directly via UPI — no gateway fees',
                ),
              ),
            _paymentOption(
              method: PaymentMethod.cod,
              icon: Icons.payments_outlined,
              title: 'Cash on Delivery',
              subtitle: 'Pay in cash when your order arrives',
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: _paymentMethod == PaymentMethod.upi
                  ? 'Pay via UPI & Place Order'
                  : 'Place Order (Pay on delivery)',
              isLoading: _isProcessing,
              onPressed: _placeOrder,
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentOption({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: _paymentMethod,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
          ],
        ),
      ),
    );
  }
}
