import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/work_post.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../utils/theme.dart';

class AdminWorkPostsScreen extends StatelessWidget {
  const AdminWorkPostsScreen({super.key});

  IconData _iconFor(WorkPostType type) {
    switch (type) {
      case WorkPostType.photo:
        return Icons.image_outlined;
      case WorkPostType.video:
        return Icons.play_circle_outline;
      case WorkPostType.blog:
        return Icons.article_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Our Work Feed')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, firestoreService),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<WorkPost>>(
        stream: firestoreService.streamWorkPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No posts yet. Tap + to upload a photo/video from your phone, '
                  'link a reel, or write a short blog post — customers will see it in the Our Work tab.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textLight),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final p = posts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    if (p.type == WorkPostType.photo && p.mediaUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(p.mediaUrl,
                            width: 44, height: 44, fit: BoxFit.cover),
                      )
                    else
                      CircleAvatar(
                        backgroundColor: AppColors.accent.withOpacity(0.15),
                        child: Icon(_iconFor(p.type), color: AppColors.primary, size: 20),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${p.type.name.toUpperCase()} • ${DateFormat('MMM d, yyyy').format(p.createdAt)}',
                            style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => firestoreService.deleteWorkPost(p.id),
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

  void _showAddDialog(BuildContext context, FirestoreService service) {
    final titleCtrl = TextEditingController();
    final linkCtrl = TextEditingController(); // for video: an external reel/YouTube link
    final bodyCtrl = TextEditingController();
    WorkPostType type = WorkPostType.photo;
    File? pickedFile;
    bool useExternalLink = false;
    bool uploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add to Our Work'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Type', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: WorkPostType.values.map((t) {
                    return ChoiceChip(
                      label: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                      selected: type == t,
                      onSelected: (_) => setState(() {
                        type = t;
                        pickedFile = null;
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),

                // PHOTO: always upload from phone
                if (type == WorkPostType.photo) ...[
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked =
                          await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (picked != null) setState(() => pickedFile = File(picked.path));
                    },
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(pickedFile == null ? 'Choose Photo' : 'Photo Selected ✓'),
                  ),
                  if (pickedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(pickedFile!, height: 100, fit: BoxFit.cover),
                      ),
                    ),
                ],

                // VIDEO: either upload from phone, or paste an external reel link
                if (type == WorkPostType.video) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Upload video'),
                          selected: !useExternalLink,
                          onSelected: (_) => setState(() => useExternalLink = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Paste reel link'),
                          selected: useExternalLink,
                          onSelected: (_) => setState(() => useExternalLink = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (useExternalLink)
                    TextField(
                      controller: linkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Video/Reel Link',
                        hintText: 'YouTube, Instagram Reel, etc.',
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
                        if (picked != null) setState(() => pickedFile = File(picked.path));
                      },
                      icon: const Icon(Icons.video_library_outlined),
                      label: Text(pickedFile == null ? 'Choose Video' : 'Video Selected ✓'),
                    ),
                ],

                const SizedBox(height: 12),
                TextField(
                  controller: bodyCtrl,
                  maxLines: type == WorkPostType.blog ? 6 : 2,
                  decoration: InputDecoration(
                    labelText: type == WorkPostType.blog ? 'Blog content' : 'Caption (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: uploading
                  ? null
                  : () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      setState(() => uploading = true);

                      String mediaUrl = linkCtrl.text.trim();
                      if (pickedFile != null) {
                        try {
                          mediaUrl = await StorageService().uploadWorkPostFile(
                            pickedFile!,
                            isVideo: type == WorkPostType.video,
                          );
                        } catch (e) {
                          setState(() => uploading = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Upload failed: $e')));
                          }
                          return;
                        }
                      }

                      final post = WorkPost(
                        id: '',
                        type: type,
                        title: titleCtrl.text.trim(),
                        mediaUrl: mediaUrl,
                        body: bodyCtrl.text.trim(),
                        createdAt: DateTime.now(),
                      );
                      await service.addWorkPost(post);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: uploading
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }
}
