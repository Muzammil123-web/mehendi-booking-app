import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart'; // PaymentMethod / PaymentStatus
import '../../models/order.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/status_badge.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Cone Orders')),
      body: StreamBuilder<List<OrderModel>>(
        stream: firestoreService.streamAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
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
                        Expanded(
                            child: Text(o.userName,
                                style: const TextStyle(fontWeight: FontWeight.bold))),
                        StatusBadge(
                            label: o.status.name.toUpperCase(), type: _statusType(o.status)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(o.userPhone, style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...o.items.map((i) => Text('${i.name} x${i.quantity}',
                        style: const TextStyle(fontSize: 13))),
                    const SizedBox(height: 6),
                    Text('Deliver to: ${o.deliveryAddress}',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      'Total: ${AppConstants.currencySymbol}${o.total.toStringAsFixed(0)} • ${o.paymentMethod.name.toUpperCase()} • ${DateFormat('MMM d').format(o.createdAt)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (o.paymentMethod == PaymentMethod.upi)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: o.paymentStatus == PaymentStatus.paid
                            ? const Text('✓ Payment verified',
                                style: TextStyle(color: AppColors.success, fontSize: 12))
                            : Row(
                                children: [
                                  const Text('Unverified UPI payment',
                                      style: TextStyle(color: AppColors.pending, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => firestoreService.markOrderPaid(
                                        o.id, 'manual-upi-verify'),
                                    child: const Text('Mark as Paid',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            decoration: TextDecoration.underline)),
                                  ),
                                ],
                              ),
                      ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<OrderStatus>(
                      value: o.status,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      items: OrderStatus.values
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s.name.toUpperCase())))
                          .toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null) {
                          firestoreService.updateOrderStatus(o.id, newStatus);
                        }
                      },
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
