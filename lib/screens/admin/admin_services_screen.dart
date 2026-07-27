import 'package:flutter/material.dart';
import '../../models/henna_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class AdminServicesScreen extends StatelessWidget {
  const AdminServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Services')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showServiceDialog(context, firestoreService),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<HennaService>>(
        stream: firestoreService.streamServices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final services = snapshot.data ?? [];
          if (services.isEmpty) {
            return const Center(
                child: Text('No services yet. Tap + to add one (e.g. Bridal Henna).'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final s = services[index];
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
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.brush, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '${AppConstants.currencySymbol}${s.price.toStringAsFixed(0)} • ${s.durationMinutes} mins',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                      onPressed: () => _showServiceDialog(context, firestoreService, existing: s),
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

  void _showServiceDialog(BuildContext context, FirestoreService service, {HennaService? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final descCtrl = TextEditingController(text: existing?.description);
    final priceCtrl = TextEditingController(text: existing?.price.toStringAsFixed(0));
    final durationCtrl = TextEditingController(text: existing?.durationMinutes.toString());
    final imageCtrl = TextEditingController(text: existing?.imageUrl);
    bool requiresDesign = existing?.requiresDesignSelection ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Service' : 'Edit Service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (e.g. Bridal Henna)')),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
                TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (₹)'), keyboardType: TextInputType.number),
                TextField(controller: durationCtrl, decoration: const InputDecoration(labelText: 'Duration (minutes)'), keyboardType: TextInputType.number),
                TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Image URL')),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: requiresDesign,
                  onChanged: (v) => setDialogState(() => requiresDesign = v ?? false),
                  title: const Text('Customer must pick a design first', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Shows the design gallery before time slots (e.g. Bridal)',
                      style: TextStyle(fontSize: 11)),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final newService = HennaService(
                  id: existing?.id ?? '',
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  price: double.tryParse(priceCtrl.text) ?? 0,
                  durationMinutes: int.tryParse(durationCtrl.text) ?? 60,
                  imageUrl: imageCtrl.text.trim(),
                  requiresDesignSelection: requiresDesign,
                );
                if (existing == null) {
                  await service.addService(newService);
                } else {
                  await service.updateService(newService);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
