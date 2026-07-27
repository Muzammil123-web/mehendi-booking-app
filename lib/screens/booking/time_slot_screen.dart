import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/henna_service.dart';
import '../../models/mehendi_design.dart';
import '../../models/time_slot.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import 'booking_confirm_screen.dart';

class TimeSlotScreen extends StatefulWidget {
  final HennaService service;
  final DateTime date;
  final MehendiDesign? design;

  const TimeSlotScreen({
    super.key,
    required this.service,
    required this.date,
    this.design,
  });

  @override
  State<TimeSlotScreen> createState() => _TimeSlotScreenState();
}

class _TimeSlotScreenState extends State<TimeSlotScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Future<List<TimeSlot>> _slotsFuture;
  TimeSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _slotsFuture = _firestoreService.getSlotsForDate(widget.date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Time Slot')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.primary.withOpacity(0.06),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(widget.date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TimeSlot>>(
              future: _slotsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final slots = snapshot.data ?? [];
                if (slots.isEmpty) {
                  return const Center(child: Text('No slots available for this date.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    final isSelected = _selectedSlot?.id == slot.id;
                    return GestureDetector(
                      onTap: slot.isBooked
                          ? null
                          : () => setState(() => _selectedSlot = slot),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: slot.isBooked
                              ? Colors.grey.shade200
                              : isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          '${slot.startTime}\n${slot.endTime}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: slot.isBooked
                                ? Colors.grey
                                : isSelected
                                    ? Colors.white
                                    : AppColors.textDark,
                            decoration:
                                slot.isBooked ? TextDecoration.lineThrough : null,
                          ),
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
                onPressed: _selectedSlot == null
                    ? null
                    : () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => BookingConfirmScreen(
                            service: widget.service,
                            date: widget.date,
                            slot: _selectedSlot!,
                            design: widget.design,
                          ),
                        ));
                      },
                child: const Text('Continue to Booking Details'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
