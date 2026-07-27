enum BookingStatus { pending, confirmed, completed, cancelled }

enum PaymentMethod { online, cod, upi }

enum PaymentStatus { pending, paid, failed }

class Booking {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String serviceId;
  final String serviceName;
  final double servicePrice;
  final String? designId;
  final String? designName;
  final DateTime date;
  final String slotId;
  final String startTime;
  final String endTime;
  final String address; // where artist should come, or "In-store"
  final double? customerLat;
  final double? customerLng;
  final BookingStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? razorpayPaymentId;
  final DateTime createdAt;
  final String? notes;

  Booking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    this.designId,
    this.designName,
    required this.date,
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.address,
    this.customerLat,
    this.customerLng,
    this.status = BookingStatus.pending,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    this.razorpayPaymentId,
    required this.createdAt,
    this.notes,
  });

  factory Booking.fromMap(Map<String, dynamic> map, String id) {
    return Booking(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      serviceId: map['serviceId'] ?? '',
      serviceName: map['serviceName'] ?? '',
      servicePrice: (map['servicePrice'] ?? 0).toDouble(),
      designId: map['designId'],
      designName: map['designName'],
      date: DateTime.parse(map['date']),
      slotId: map['slotId'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      address: map['address'] ?? '',
      customerLat: map['customerLat']?.toDouble(),
      customerLng: map['customerLng']?.toDouble(),
      status: BookingStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => BookingStatus.pending),
      paymentMethod: PaymentMethod.values.firstWhere(
          (e) => e.name == map['paymentMethod'],
          orElse: () => PaymentMethod.cod),
      paymentStatus: PaymentStatus.values.firstWhere(
          (e) => e.name == map['paymentStatus'],
          orElse: () => PaymentStatus.pending),
      razorpayPaymentId: map['razorpayPaymentId'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'servicePrice': servicePrice,
      'designId': designId,
      'designName': designName,
      'date': date.toIso8601String(),
      'slotId': slotId,
      'startTime': startTime,
      'endTime': endTime,
      'address': address,
      'customerLat': customerLat,
      'customerLng': customerLng,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'paymentStatus': paymentStatus.name,
      'razorpayPaymentId': razorpayPaymentId,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
    };
  }
}
