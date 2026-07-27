import 'package:flutter/material.dart';
import '../../models/henna_service.dart';
import '../../models/mehendi_design.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import 'time_slot_screen.dart';

/// Shown after picking a service that requires a design choice (e.g. Bridal).
/// The customer taps a design photo to select the pattern they want applied,
/// then continues on to pick a time slot.
class DesignGalleryScreen extends StatefulWidget {
  final HennaService service;
  final DateTime date;
  final MehendiDesign? preselectedDesign;

  const DesignGalleryScreen({
    super.key,
    required this.service,
    required this.date,
    this.preselectedDesign,
  });

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  MehendiDesign? _selectedDesign;

  @override
  void initState() {
    super.initState();
    _selectedDesign = widget.preselectedDesign;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Design')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.06),
            child: const Text(
              'Tap a design to select the pattern you\'d like applied for your appointment',
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MehendiDesign>>(
              stream: _firestoreService.streamDesigns(),
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
                        'No designs available yet. Please check back soon or contact us.',
                        style: TextStyle(color: AppColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: designs.length,
                  itemBuilder: (context, index) {
                    final design = designs[index];
                    final isSelected = _selectedDesign?.id == design.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDesign = design),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  design.imageUrl.isEmpty
                                      ? Container(
                                          color: AppColors.accent.withOpacity(0.15),
                                          child: const Icon(Icons.brush,
                                              size: 36, color: AppColors.accent),
                                        )
                                      : Image.network(
                                          design.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: AppColors.accent.withOpacity(0.15),
                                            child: const Icon(Icons.broken_image,
                                                size: 32, color: AppColors.accent),
                                          ),
                                        ),
                                  if (isSelected)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check,
                                            size: 16, color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                design.name,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedDesign == null
                    ? null
                    : () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TimeSlotScreen(
                            service: widget.service,
                            date: widget.date,
                            design: _selectedDesign,
                          ),
                        ));
                      },
                child: const Text('Continue to Time Slot'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
