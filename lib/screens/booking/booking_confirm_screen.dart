import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/henna_service.dart';
import '../../models/mehendi_design.dart';
import '../../models/time_slot.dart';
import '../../models/booking.dart';
import '../../models/shop_settings.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../home/home_screen.dart';
import '../map_picker_screen.dart';

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
  PaymentMethod _paymentMethod = PaymentMethod.cod;
  bool _isProcessing = false;
  ShopSettings? _shopSettings;
  double? _pickedLat;
  double? _pickedLng;

  @override
  void initState() {
    super.initState();
    _loadShopSettings();
  }

  Future<void> _loadShopSettings() async {
    final settings = await _firestoreService.getShopSettings();
    if (mounted) setState(() => _shopSettings = settings);
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _pickedLat = result.latitude;
        _pickedLng = result.longitude;
      });
    }
  }

  Future<void> _confirmBooking() async {
    final user = context.read<AuthProvider>().appUser;
    if (user == null) return;

    if (_addressCtrl.text.trim().isEmpty && _pickedLat == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a location on the map, or type "In-store"')));
      return;
    }

    setState(() => _isProcessing = true);

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
      customerLat: _pickedLat,
      customerLng: _pickedLng,
      paymentMethod: _paymentMethod,
      createdAt: DateTime.now(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      await _firestoreService.createBooking(booking);
      if (!mounted) return;
      _showSuccessAndExit(
        extraNote: _paymentMethod == PaymentMethod.upi
            ? 'Once the artist accepts your request, you\'ll be able to complete the UPI payment from My Orders.'
            : null,
      );
    } catch (e) {
      _showError('Could not create booking. Please try again.');
    }
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
              'We\'ll confirm it as soon as the artist accepts — you can track its status in My Orders.'
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
            const Text('Location', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Booking this for someone else? Just pick their location on the map.',
              style: TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickLocation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pickedLat != null ? AppColors.success : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.map_outlined,
                        color: _pickedLat != null ? AppColors.success : AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pickedLat != null
                            ? 'Location selected ✓ — tap to change'
                            : 'Select location on map',
                        style: TextStyle(
                            color: _pickedLat != null ? AppColors.success : AppColors.textDark),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Flat/floor, landmark, or type "In-store" (optional)',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
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
                  subtitle: 'Pay once the artist accepts your request',
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
              label: 'Send Booking Request',
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
