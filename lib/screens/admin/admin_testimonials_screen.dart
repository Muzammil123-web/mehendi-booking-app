import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/review.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class AdminTestimonialsScreen extends StatelessWidget {
  const AdminTestimonialsScreen({super.key});

  String _sourceLabel(ReviewSource s) {
    switch (s) {
      case ReviewSource.whatsapp:
        return 'WhatsApp';
      case ReviewSource.instagram:
        return 'Instagram';
      case ReviewSource.app:
        return 'In-app';
      case ReviewSource.other:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Testimonials')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddDialog(context, firestoreService),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Review>>(
        stream: firestoreService.streamTestimonials(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = snapshot.data ?? [];
          if (reviews.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No testimonials yet. Tap + to add praise you received on WhatsApp or Instagram — '
                  'it\'ll show up in a "What Customers Say" carousel on the Book tab.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textLight),
                ),
              ),
            );
          }
          final sorted = [...reviews]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final r = sorted[index];
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
                      children: [
                        Expanded(
                          child: Text(r.userName,
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('via ${_sourceLabel(r.source)}',
                              style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                          onPressed: () => firestoreService.deleteReview(r.id),
                        ),
                      ],
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < r.rating ? Icons.star : Icons.star_border,
                          size: 15,
                          color: Colors.amber.shade600,
                        ),
                      ),
                    ),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.comment, style: const TextStyle(fontSize: 13)),
                    ],
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM d, yyyy').format(r.createdAt),
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, FirestoreService service) {
    final nameCtrl = TextEditingController();
    final commentCtrl = TextEditingController();
    double rating = 5;
    ReviewSource source = ReviewSource.whatsapp;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Testimonial'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Customer Name'),
                ),
                const SizedBox(height: 12),
                const Text('Rating', style: TextStyle(fontSize: 12)),
                Row(
                  children: List.generate(5, (i) {
                    final starValue = i + 1;
                    return IconButton(
                      onPressed: () => setState(() => rating = starValue.toDouble()),
                      icon: Icon(
                        starValue <= rating ? Icons.star : Icons.star_border,
                        color: AppColors.accent,
                      ),
                    );
                  }),
                ),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'What they said',
                    hintText: 'Paste or type their message here',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Received via', style: TextStyle(fontSize: 12)),
                Wrap(
                  spacing: 8,
                  children: [ReviewSource.whatsapp, ReviewSource.instagram, ReviewSource.other]
                      .map((s) => ChoiceChip(
                            label: Text(s == ReviewSource.whatsapp
                                ? 'WhatsApp'
                                : s == ReviewSource.instagram
                                    ? 'Instagram'
                                    : 'Other'),
                            selected: source == s,
                            onSelected: (_) => setState(() => source = s),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final review = Review(
                  id: '',
                  userId: '',
                  userName: nameCtrl.text.trim(),
                  targetType: ReviewTargetType.general,
                  targetId: '',
                  targetName: 'General',
                  sourceId: const Uuid().v4(),
                  source: source,
                  rating: rating,
                  comment: commentCtrl.text.trim(),
                  createdAt: DateTime.now(),
                );
                await service.submitReview(review);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
