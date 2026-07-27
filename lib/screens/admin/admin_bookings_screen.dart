import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/status_badge.dart';

class AdminBookingsScreen extends StatelessWidget {
  const AdminBookingsScreen({super.key});

  Future<void> _pickNewDate(BuildContext context, FirestoreService service, Booking booking) async {
    final newDate = await showDatePicker(
      context: context,
      initialDate: booking.date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (newDate != null) {
      await service.rescheduleBooking(booking.id, newDate);
    }
  }

  void _confirmDecline(BuildContext context, FirestoreService service, Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline this booking?'),
        content: Text(
          'This will free up the ${booking.startTime} slot on '
          '${DateFormat('MMM d').format(booking.date)} for other customers.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await service.declineBooking(booking);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Decline', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  StatusType _statusType(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
      case BookingStatus.completed:
        return StatusType.success;
      case BookingStatus.pending:
        return StatusType.pending;
      case BookingStatus.cancelled:
        return StatusType.error;
    }
  }

  String _statusLabel(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'AWAITING YOUR APPROVAL';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'DECLINED / CANCELLED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('All Bookings')),
      body: StreamBuilder<List<Booking>>(
        stream: firestoreService.streamAllBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text('No bookings yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(b.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        StatusBadge(
                            label: _statusLabel(b.status), type: _statusType(b.status)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(b.userPhone, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('${b.serviceName} • ${AppConstants.currencySymbol}${b.servicePrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          b.paymentMethod == PaymentMethod.online
                              ? 'Paid Online'
                              : b.paymentMethod == PaymentMethod.upi
                                  ? 'UPI'
                                  : 'Cash on visit',
                          style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                        ),
                        if (b.paymentMethod == PaymentMethod.upi &&
                            b.paymentStatus != PaymentStatus.paid) ...[
                          const SizedBox(width: 8),
                          const Text('• Unverified',
                              style: TextStyle(color: AppColors.pending, fontSize: 12)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              await firestoreService.markBookingPaid(b.id, 'manual-upi-verify');
                            },
                            child: const Text('Mark as Paid',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline)),
                          ),
                        ] else if (b.paymentMethod == PaymentMethod.upi &&
                            b.paymentStatus == PaymentStatus.paid) ...[
                          const SizedBox(width: 8),
                          const Text('• Verified ✓',
                              style: TextStyle(color: AppColors.success, fontSize: 12)),
                        ],
                      ],
                    ),
                    if (b.designName != null) ...[
                      const SizedBox(height: 4),
                      Text('Design: ${b.designName}',
                          style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text('${DateFormat('MMM d, yyyy').format(b.date)} • ${b.startTime}',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                        if (b.status == BookingStatus.pending ||
                            b.status == BookingStatus.confirmed) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _pickNewDate(context, firestoreService, b),
                            child: const Text('Change date',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Address: ${b.address}',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                    if (b.customerLat != null && b.customerLng != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: GestureDetector(
                          onTap: () => launchUrl(Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${b.customerLat},${b.customerLng}')),
                          child: const Row(
                            children: [
                              Icon(Icons.map_outlined, size: 14, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text('View exact location on map',
                                  style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    if (b.status == BookingStatus.pending)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDecline(context, firestoreService, b),
                              icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                              label: const Text('Decline', style: TextStyle(color: AppColors.error)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.error),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => firestoreService.acceptBooking(b),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Accept'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (b.status == BookingStatus.confirmed)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  firestoreService.updateBookingStatus(b.id, BookingStatus.completed),
                              child: const Text('Mark as Completed'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
