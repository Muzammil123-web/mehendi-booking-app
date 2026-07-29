import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/henna_service.dart';
import '../../models/mehendi_design.dart';
import '../../models/time_slot.dart';
import '../../models/booking.dart';
import '../../models/shop_settings.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';
import '../../services/location_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../home/home_screen.dart';

class BookingConfirmScreen extends StatefulWidget {
  final HennaService service;
  final DateTime date;
  final TimeSlot slot;
  final MehendiDesign? design;

  const BookingConfirmScreen({
    super.key,
    required this.service,
    required this.date,
    required this.slot,
    this.design,
  });

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  late final PaymentService _paymentService;
  PaymentMethod _paymentMethod = PaymentMethod.cod;
  bool _isProcessing = false;
  bool _fetchingLocation = false;
  double? _customerLat;
  double? _customerLng;
  String? _withinRangeText;
  ShopSettings? _shopSettings;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _loadShopSettings();
  }

  Future<void> _loadShopSettings() async {
    final settings = await _firestoreService.getShopSettings();
    if (mounted) setState(() => _shopSettings = settings);
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  Future<void> _detectLocationNow() async {
    setState(() => _fetchingLocation = true);
    final result = await LocationService.getCurrentLocation();
    setState(() => _fetchingLocation = false);

    if (result == null) {
      _showError(
          'Could not detect your location. You can still type your address manually.');
      return;
    }

    _customerLat = result.latitude;
    _customerLng = result.longitude;
    if (result.address != null && result.address!.isNotEmpty) {
      _addressCtrl.text = result.address!;
    }
    setState(() => _withinRangeText = 'Location captured ✓');
  }

  /// Best-effort capture of the customer's GPS location for the artist's
  /// reference (so they can find the address on a map). Never blocks
  /// submission — if location can't be captured, the booking still goes
  /// through using whatever address text was typed.
  Future<bool> _captureAndValidateLocation() async {
    if (_customerLat != null && _customerLng != null) return true;

    setState(() => _fetchingLocation = true);
    final result = await LocationService.getCurrentLocation();
    setState(() => _fetchingLocation = false);

    if (result != null) {
      _customerLat = result.latitude;
      _customerLng = result.longitude;
    }
    return true;
  }

  Future<void> _confirmBooking() async {
    final user = context.read<AuthProvider>().appUser;
    if (user == null) return;

    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter your address or "In-store"')));
      return;
    }

    setState(() => _isProcessing = true);

    final withinRange = await _captureAndValidateLocation();
    if (!withinRange) {
      setState(() => _isProcessing = false);
      return;
    }

    final booking = Booking(
      id: const Uuid().v4(),
      userId: user.uid,
      userName: user.name,
      userPhone: user.phone,
      serviceId: widget.service.id,
      serviceName: widget.service.name,
      servicePrice: widget.service.price,
      designId: widget.design?.id,
      designName: widget.design?.name,
      date: widget.date,
      slotId: widget.slot.id,
      startTime: widget.slot.startTime,
      endTime: widget.slot.endTime,
      address: _addressCtrl.text.trim(),
      customerLat: _customerLat,
      customerLng: _customerLng,
      paymentMethod: _paymentMethod,
      createdAt: DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (_paymentMethod == PaymentMethod.cod) {
      try {
        await _firestoreService.createBooking(booking);
        if (!mounted) return;
        _showSuccessAndExit();
      } catch (e) {
        _showError('Could not create booking. Please try again.');
      }
      return;
    }

    if (_paymentMethod == PaymentMethod.upi) {
      final upiId = _shopSettings?.upiId ?? '';
      if (upiId.isEmpty) {
        _showError('UPI payment isn\'t set up yet — please choose another payment method.');
        return;
      }
      try {
        await _firestoreService.createBooking(booking);
        final uri = Uri.parse(
          'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(_shopSettings?.businessName ?? 'Mehendi Studio')}'
          '&am=${widget.service.price.toStringAsFixed(2)}&cu=INR'
          '&tn=${Uri.encodeComponent('${widget.service.name} booking')}',
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
        if (!mounted) return;
        _showSuccessAndExit(
          extraNote:
              'Please complete the payment in your UPI app. We\'ll verify it and confirm your booking shortly.',
        );
      } catch (e) {
        _showError('Could not open your UPI app. Please try again.');
      }
      return;
    }

    // Online payment via Razorpay
    _paymentService.openCheckout(
      amount: widget.service.price,
      name: widget.service.name,
      description: '${widget.service.name} - ${DateFormat('MMM d').format(widget.date)}',
      contactPhone: user.phone,
      contactEmail: user.email,
      onSuccess: (paymentId) async {
        try {
          final bookingId = await _firestoreService.createBooking(booking);
          await _firestoreService.markBookingPaid(bookingId, paymentId);
          if (!mounted) return;
          _showSuccessAndExit();
        } catch (e) {
          _showError('Payment succeeded but booking failed. Contact support with payment ID: $paymentId');
        }
      },
      onError: (message) {
        _showError('Payment failed: $message');
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.error));
  }

  void _showSuccessAndExit({String? extraNote}) {
    setState(() => _isProcessing = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top, color: AppColors.pending, size: 56),
            const SizedBox(height: 16),
            const Text('Booking Requested',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Your ${widget.service.name} request for ${DateFormat('MMM d').format(widget.date)}, ${widget.slot.startTime} has been sent. '
              'We\'ll confirm it as soon as the artist accepts — you can track its status in My Activity.'
              '${extraNote != null ? '\n\n$extraNote' : ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _summaryCard(),
            const SizedBox(height: 24),
            const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Where should the artist visit? (or type "In-store")',
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  icon: _fetchingLocation
                      ? const SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, color: AppColors.primary),
                  tooltip: 'Detect my exact location',
                  onPressed: _fetchingLocation ? null : _detectLocationNow,
                ),
              ),
            ),
            if (_customerLat != null) ...[
              const SizedBox(height: 6),
              Text(
                _withinRangeText ?? 'Location captured ✓',
                style: TextStyle(
                  fontSize: 11,
                  color: _withinRangeText != null && _withinRangeText!.contains('Sorry')
                      ? AppColors.error
                      : AppColors.success,
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Notes (optional)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Any design preference or special instructions',
                prefixIcon: Icon(Icons.edit_note),
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
              subtitle: 'Pay in cash when the artist arrives',
            ),
            const SizedBox(height: 32),
            CustomButton(
              label: _fetchingLocation
                  ? 'Checking your location...'
                  : _paymentMethod == PaymentMethod.upi
                      ? 'Pay via UPI & Send Request'
                      : 'Send Booking Request (Pay on visit)',
              isLoading: _isProcessing,
              onPressed: _confirmBooking,
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.service.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          if (widget.design != null) ...[
            const SizedBox(height: 4),
            _summaryRow(Icons.brush, 'Design: ${widget.design!.name}'),
          ],
          const SizedBox(height: 10),
          _summaryRow(Icons.calendar_today, DateFormat('EEEE, MMM d, yyyy').format(widget.date)),
          const SizedBox(height: 6),
          _summaryRow(Icons.access_time, '${widget.slot.startTime} - ${widget.slot.endTime}'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${AppConstants.currencySymbol}${widget.service.price.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textLight),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
      ],
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
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
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
