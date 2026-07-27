/// Represents a single bookable time slot on a given date.
/// Slots are generated per-day by the admin (or auto-generated) and
/// marked unavailable once booked.
class TimeSlot {
  final String id;
  final DateTime date; // date-only (year, month, day)
  final String startTime; // e.g. "10:00 AM"
  final String endTime; // e.g. "11:00 AM"
  final bool isBooked;
  final String? bookedByUid;

  TimeSlot({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.isBooked = false,
    this.bookedByUid,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map, String id) {
    return TimeSlot(
      id: id,
      date: DateTime.parse(map['date']),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      isBooked: map['isBooked'] ?? false,
      bookedByUid: map['bookedByUid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'isBooked': isBooked,
      'bookedByUid': bookedByUid,
    };
  }
}
