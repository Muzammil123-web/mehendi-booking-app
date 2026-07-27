class AppConstants {
  // TODO: Replace with your real Razorpay KEY ID from https://dashboard.razorpay.com
  // Use the TEST key (starts with rzp_test_) while developing.
  static const String razorpayKeyId = 'rzp_test_XXXXXXXXXXXX';

  static const String appName = 'Mehendi Studio';
  static const String currencySymbol = '₹';

  static const double deliveryFeeFlat = 49.0;
  static const double freeDeliveryAboveAmount = 499.0;

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String servicesCollection = 'services';
  static const String designsCollection = 'mehendi_designs';
  static const String reviewsCollection = 'reviews';
  static const String workPostsCollection = 'work_posts';
  static const String slotsCollection = 'time_slots';
  static const String bookingsCollection = 'bookings';
  static const String productsCollection = 'products';
  static const String ordersCollection = 'orders';

  static const List<String> defaultTimeSlots = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 03:00 PM',
    '03:00 PM - 04:00 PM',
    '04:00 PM - 05:00 PM',
    '05:00 PM - 06:00 PM',
    '06:00 PM - 07:00 PM',
  ];
}
