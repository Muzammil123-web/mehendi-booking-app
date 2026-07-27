import 'package:flutter/material.dart';
import '../../models/mehendi_design.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';

class AdminDesignsScreen extends StatelessWidget {
  const AdminDesignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Designs')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showDesignDialog(context, firestoreService),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<MehendiDesign>>(
        stream: firestoreService.streamDesigns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final designs = snapshot.data ?? [];
          if (designs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No designs yet. Tap + to add a design photo (e.g. "Peacock Bridal").\n\n'
                  'Customers will see these when they book a service marked '
                  '"Customer must pick a design first".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textLight),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: designs.length,
            itemBuilder: (context, index) {
              final d = designs[index];
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
                    Container(
                      width: 50,
                      height: 50,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: d.imageUrl.isEmpty
                          ? const Icon(Icons.brush, color: AppColors.primary)
                          : Image.network(
                              d.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, color: AppColors.primary),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (d.description.isNotEmpty)
                            Text(
                              d.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      onPressed: () => _showDesignDialog(context, firestoreService, existing: d),
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

  void _showDesignDialog(BuildContext context, FirestoreService service, {MehendiDesign? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final descCtrl = TextEditingController(text: existing?.description);
    final imageCtrl = TextEditingController(text: existing?.imageUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Design' : 'Edit Design'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. Peacock Bridal)')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
              TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Photo URL')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final newDesign = MehendiDesign(
                id: existing?.id ?? '',
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim(),
                imageUrl: imageCtrl.text.trim(),
              );
              if (existing == null) {
                await service.addDesign(newDesign);
              } else {
                await service.updateDesign(newDesign);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
