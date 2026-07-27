import 'package:flutter/material.dart';
import '../models/review.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../utils/theme.dart';
import 'package:provider/provider.dart';

/// Shows a 1-5 star picker + optional comment, then submits a Review.
/// Call via [showRatingDialog] after a booking is completed or an order
/// is delivered.
Future<void> showRatingDialog(
  BuildContext context, {
  required ReviewTargetType targetType,
  required String targetId,
  required String targetName,
  required String sourceId,
}) async {
  final user = context.read<AuthProvider>().appUser;
  if (user == null) return;

  double rating = 5;
  final commentCtrl = TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text('Rate $targetName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starValue = i + 1;
                return IconButton(
                  onPressed: () => setState(() => rating = starValue.toDouble()),
                  icon: Icon(
                    starValue <= rating ? Icons.star : Icons.star_border,
                    color: AppColors.accent,
                    size: 28,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add a comment (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final review = Review(
                id: '',
                userId: user.uid,
                userName: user.name,
                targetType: targetType,
                targetId: targetId,
                targetName: targetName,
                sourceId: sourceId,
                rating: rating,
                comment: commentCtrl.text.trim(),
                createdAt: DateTime.now(),
              );
              await FirestoreService().submitReview(review);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thanks for your review!')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    ),
  );
}
