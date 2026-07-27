import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/henna_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import 'design_gallery_screen.dart';
import 'time_slot_screen.dart';

class BookingCalendarScreen extends StatefulWidget {
  const BookingCalendarScreen({super.key});

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  HennaService? _selectedService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Your Mehendi')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
                ],
              ),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 60)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Choose a service',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<HennaService>>(
              stream: _firestoreService.streamServices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final services = snapshot.data ?? [];
                if (services.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No services available yet. Please check back soon or contact us.',
                      style: TextStyle(color: AppColors.textLight),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    final isSelected = _selectedService?.id == service.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedService = service),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04), blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.brush, color: AppColors.accent),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(
                                    service.requiresDesignSelection
                                        ? '${service.durationMinutes} mins • pick a design first'
                                        : '${service.durationMinutes} mins',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.textLight),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${AppConstants.currencySymbol}${service.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            Radio<String>(
                              value: service.id,
                              groupValue: _selectedService?.id,
                              activeColor: AppColors.primary,
                              onChanged: (_) => setState(() => _selectedService = service),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
      floatingActionButton: _selectedService == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: () {
                if (_selectedService!.requiresDesignSelection) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => DesignGalleryScreen(
                      service: _selectedService!,
                      date: _selectedDay,
                    ),
                  ));
                } else {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TimeSlotScreen(
                      service: _selectedService!,
                      date: _selectedDay,
                    ),
                  ));
                }
              },
              label: const Text('Continue'),
              icon: const Icon(Icons.arrow_forward),
            ),
    );
  }
}
