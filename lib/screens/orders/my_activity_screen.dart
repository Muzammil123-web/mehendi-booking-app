import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/review.dart';
import '../../models/work_post.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

/// The "Our Work" tab: purely the studio's content feed (videos, photos,
/// blog posts) and customer testimonials — no personal transactional data.
/// Your own bookings/orders live under Profile instead.
class MyActivityScreen extends StatelessWidget {
  const MyActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Our Work')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<List<WorkPost>>(
            stream: firestoreService.streamWorkPosts(),
            builder: (context, snapshot) {
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Text('Our portfolio will appear here soon.',
                    style: TextStyle(color: AppColors.textLight, fontSize: 12));
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
          const SizedBox(height: 8),
          const Text('What Customers Say',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: StreamBuilder<List<Review>>(
              stream: firestoreService.streamAllReviews(),
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
        ],
      ),
    );
  }
}
