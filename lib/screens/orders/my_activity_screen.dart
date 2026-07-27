import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking.dart';
import '../../models/review.dart';
import '../../models/work_post.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/status_timeline.dart';
import '../../widgets/rating_dialog.dart';

/// The "Bookings" tab: your booking history/status, plus the studio's
/// portfolio and customer testimonials (moved here from the Book tab so
/// the Book tab stays focused purely on booking a service).
class MyActivityScreen extends StatelessWidget {
  const MyActivityScreen({super.key});

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
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<List<WorkPost>>(
            stream: firestoreService.streamWorkPosts(),
            builder: (context, snapshot) {
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Our Work', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Our portfolio will appear here soon.',
                        style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ],
                );
              }
              final videos = posts.where((p) => p.type == WorkPostType.video).toList();
              final photos = posts.where((p) => p.type == WorkPostType.photo).toList();
              final blogs = posts.where((p) => p.type == WorkPostType.blog).toList();

              Widget section(String heading, List<WorkPost> items) {
                if (items.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(heading,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ...items.map((p) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (p.type == WorkPostType.photo && p.mediaUrl.isNotEmpty)
                                  Image.network(p.mediaUrl,
                                      width: double.infinity, height: 180, fit: BoxFit.cover),
                                if (p.type == WorkPostType.video)
                                  GestureDetector(
                                    onTap: () => launchUrl(Uri.parse(p.mediaUrl),
                                        mode: LaunchMode.externalApplication),
                                    child: Container(
                                      width: double.infinity,
                                      height: 140,
                                      color: AppColors.primary.withOpacity(0.08),
                                      child: const Center(
                                        child: Icon(Icons.play_circle_fill,
                                            size: 48, color: AppColors.primary),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 14)),
                                      if (p.body.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(p.body,
                                            style: const TextStyle(
                                                fontSize: 12, color: AppColors.textLight)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  section('Videos', videos),
                  section('Photos', photos),
                  section('From the Studio', blogs),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const Text('What Customers Say',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: StreamBuilder<List<Review>>(
              stream: firestoreService.streamTestimonials(),
              builder: (context, snapshot) {
                final testimonials = snapshot.data ?? [];
                if (testimonials.isEmpty) {
                  return const Center(
                    child: Text('Reviews will appear here soon.',
                        style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                  );
                }
                final sorted = [...testimonials]
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final r = sorted[index];
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < r.rating ? Icons.star : Icons.star_border,
                                size: 12,
                                color: Colors.amber.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Expanded(
                            child: Text(r.comment,
                                maxLines: 3, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11)),
                          ),
                          Text('— ${r.userName}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textLight)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text('Your Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (user == null)
            const SizedBox()
          else
            StreamBuilder<List<Booking>>(
              stream: firestoreService.streamUserBookings(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final bookings = snapshot.data ?? [];
                if (bookings.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No bookings yet', style: TextStyle(color: AppColors.textLight)),
                  );
                }
                return Column(
                  children: bookings.map((b) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  b.designName != null
                                      ? '${b.serviceName} — ${b.designName}'
                                      : b.serviceName,
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
                          Text(b.address,
                              style: const TextStyle(color: AppColors.textLight, fontSize: 13)),
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
                                  child: const Text('Cancel',
                                      style: TextStyle(color: AppColors.error)),
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
                                    icon: const Icon(Icons.star_outline,
                                        size: 18, color: AppColors.accent),
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
            ),
        ],
      ),
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
