import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/booking.dart';
import '../../models/order.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/status_timeline.dart';
import '../../widgets/rating_dialog.dart';

/// Combined screen for everything the customer has bought/booked — a
/// "Bookings" tab (mehendi appointments) and an "Orders" tab (henna cone
/// purchases), reachable from Profile.
class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Bookings'),
              Tab(text: 'Cone Orders'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_BookingsTab(), _OrdersTab()],
        ),
      ),
    );
  }
}

class _BookingsTab extends StatelessWidget {
  const _BookingsTab();

  static const _stages = ['Requested', 'Confirmed', 'Completed'];

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
        return 'PENDING APPROVAL';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  int _stageIndex(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 0;
      case BookingStatus.confirmed:
        return 1;
      case BookingStatus.completed:
        return 2;
      case BookingStatus.cancelled:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    if (user == null) return const SizedBox();
    final firestoreService = FirestoreService();

    return StreamBuilder<List<Booking>>(
      stream: firestoreService.streamUserBookings(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return const Center(
            child: Text('No bookings yet', style: TextStyle(color: AppColors.textLight)),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: bookings.map((b) {
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
                        child: Text(
                          b.designName != null ? '${b.serviceName} — ${b.designName}' : b.serviceName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      StatusBadge(
                          label: _statusLabel(b.status), type: _statusType(b.status)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${DateFormat('MMM d, yyyy').format(b.date)} • ${b.startTime}',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(b.address, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                  if (b.status != BookingStatus.cancelled) ...[
                    const SizedBox(height: 14),
                    StatusTimeline(stages: _stages, currentIndex: _stageIndex(b.status)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppConstants.currencySymbol}${b.servicePrice.toStringAsFixed(0)} • ${b.paymentMethod == PaymentMethod.online ? 'Paid Online' : b.paymentMethod == PaymentMethod.upi ? 'UPI' : 'COD'}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (b.status == BookingStatus.pending ||
                          b.status == BookingStatus.confirmed)
                        TextButton(
                          onPressed: () => _confirmCancel(context, firestoreService, b),
                          child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                        ),
                    ],
                  ),
                  if (b.status == BookingStatus.completed)
                    FutureBuilder<bool>(
                      future: firestoreService.hasReviewedSource(b.id),
                      builder: (context, reviewSnap) {
                        if (reviewSnap.data == true) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('✓ You rated this service',
                                style: TextStyle(color: AppColors.success, fontSize: 12)),
                          );
                        }
                        return Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => showRatingDialog(
                              context,
                              targetType: ReviewTargetType.service,
                              targetId: b.serviceId,
                              targetName: b.serviceName,
                              sourceId: b.id,
                            ),
                            icon: const Icon(Icons.star_outline, size: 18, color: AppColors.accent),
                            label: const Text('Rate this service',
                                style: TextStyle(color: AppColors.accent)),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _confirmCancel(BuildContext context, FirestoreService service, Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text('This will free up the time slot for others.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          TextButton(
            onPressed: () async {
              await service.cancelBooking(booking);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  static const _stages = ['Placed', 'Packed', 'Shipped', 'Delivered'];

  StatusType _statusType(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return StatusType.success;
      case OrderStatus.cancelled:
        return StatusType.error;
      case OrderStatus.placed:
        return StatusType.pending;
      default:
        return StatusType.neutral;
    }
  }

  int _stageIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.packed:
        return 1;
      case OrderStatus.shipped:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.cancelled:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().appUser;
    if (user == null) return const SizedBox();
    final firestoreService = FirestoreService();

    return StreamBuilder<List<OrderModel>>(
      stream: firestoreService.streamUserOrders(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(
            child: Text('No orders yet', style: TextStyle(color: AppColors.textLight)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final o = orders[index];
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
                      Text('Order #${o.id.substring(0, o.id.length > 6 ? 6 : o.id.length)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      StatusBadge(
                          label: o.status.name.toUpperCase(), type: _statusType(o.status)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${o.items.length} item(s) • ${DateFormat('MMM d, yyyy').format(o.createdAt)}',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                  if (o.status != OrderStatus.cancelled) ...[
                    const SizedBox(height: 14),
                    StatusTimeline(stages: _stages, currentIndex: _stageIndex(o.status)),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    '${AppConstants.currencySymbol}${o.total.toStringAsFixed(0)} • ${o.paymentMethod == PaymentMethod.online ? 'Paid Online' : o.paymentMethod == PaymentMethod.upi ? 'UPI' : 'COD'}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (o.status == OrderStatus.delivered)
                    FutureBuilder<bool>(
                      future: firestoreService.hasReviewedSource(o.id),
                      builder: (context, reviewSnap) {
                        if (reviewSnap.data == true) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text('✓ You rated this order',
                                style: TextStyle(color: AppColors.success, fontSize: 12)),
                          );
                        }
                        return Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => showRatingDialog(
                              context,
                              targetType: ReviewTargetType.product,
                              targetId: o.items.isNotEmpty ? o.items.first.productId : o.id,
                              targetName: o.items.isNotEmpty ? o.items.first.name : 'your order',
                              sourceId: o.id,
                            ),
                            icon: const Icon(Icons.star_outline, size: 18, color: AppColors.accent),
                            label: const Text('Rate this order',
                                style: TextStyle(color: AppColors.accent)),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
