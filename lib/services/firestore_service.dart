import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/henna_service.dart';
import '../models/mehendi_design.dart';
import '../models/time_slot.dart';
import '../models/booking.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/shop_settings.dart';
import '../models/work_post.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- SERVICES (mehendi design types) ----------------

  Stream<List<HennaService>> streamServices() {
    return _db
        .collection(AppConstants.servicesCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => HennaService.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addService(HennaService service) async {
    await _db.collection(AppConstants.servicesCollection).add(service.toMap());
  }

  Future<void> updateService(HennaService service) async {
    await _db
        .collection(AppConstants.servicesCollection)
        .doc(service.id)
        .update(service.toMap());
  }

  // ---------------- MEHENDI DESIGNS (design gallery) ----------------

  Stream<List<MehendiDesign>> streamDesigns() {
    return _db
        .collection(AppConstants.designsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MehendiDesign.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addDesign(MehendiDesign design) async {
    await _db.collection(AppConstants.designsCollection).add(design.toMap());
  }

  Future<void> updateDesign(MehendiDesign design) async {
    await _db
        .collection(AppConstants.designsCollection)
        .doc(design.id)
        .update(design.toMap());
  }

  // ---------------- TIME SLOTS ----------------

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Fetch slots for a given date; auto-generates the default set if none exist yet.
  Future<List<TimeSlot>> getSlotsForDate(DateTime date) async {
    final dateKey = _dateKey(date);
    final snap = await _db
        .collection(AppConstants.slotsCollection)
        .where('dateKey', isEqualTo: dateKey)
        .get();

    if (snap.docs.isNotEmpty) {
      return snap.docs.map((d) => TimeSlot.fromMap(d.data(), d.id)).toList();
    }

    // Auto-generate default slots for this date if admin hasn't customized them.
    final batch = _db.batch();
    final List<TimeSlot> generated = [];
    for (final range in AppConstants.defaultTimeSlots) {
      final parts = range.split(' - ');
      final docRef = _db.collection(AppConstants.slotsCollection).doc();
      final slot = TimeSlot(
        id: docRef.id,
        date: DateTime(date.year, date.month, date.day),
        startTime: parts[0],
        endTime: parts[1],
      );
      final map = slot.toMap();
      map['dateKey'] = dateKey;
      batch.set(docRef, map);
      generated.add(slot);
    }
    await batch.commit();
    return generated;
  }

  Future<void> bookSlot(String slotId, String userUid) async {
    await _db.collection(AppConstants.slotsCollection).doc(slotId).update({
      'isBooked': true,
      'bookedByUid': userUid,
    });
  }

  Future<void> releaseSlot(String slotId) async {
    await _db.collection(AppConstants.slotsCollection).doc(slotId).update({
      'isBooked': false,
      'bookedByUid': null,
    });
  }

  // ---------------- BOOKINGS ----------------

  Future<String> createBooking(Booking booking) async {
    final docRef =
        await _db.collection(AppConstants.bookingsCollection).add(booking.toMap());
    await bookSlot(booking.slotId, booking.userId);
    return docRef.id;
  }

  Stream<List<Booking>> streamUserBookings(String userId) {
    return _db
        .collection(AppConstants.bookingsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final bookings = snap.docs.map((d) => Booking.fromMap(d.data(), d.id)).toList();
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookings;
    });
  }

  Stream<List<Booking>> streamAllBookings() {
    return _db
        .collection(AppConstants.bookingsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Booking.fromMap(d.data(), d.id)).toList());
  }

  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await _db
        .collection(AppConstants.bookingsCollection)
        .doc(bookingId)
        .update({'status': status.name});
  }

  Future<void> markBookingPaid(String bookingId, String paymentId) async {
    // Payment success does NOT auto-confirm the booking anymore — the artist
    // still needs to review and accept it. The slot is already held (see
    // createBooking -> bookSlot) so no one else can grab it in the meantime.
    await _db.collection(AppConstants.bookingsCollection).doc(bookingId).update({
      'paymentStatus': PaymentStatus.paid.name,
      'razorpayPaymentId': paymentId,
    });
  }

  Future<void> cancelBooking(Booking booking) async {
    await updateBookingStatus(booking.id, BookingStatus.cancelled);
    await releaseSlot(booking.slotId);
  }

  /// Artist/admin accepts a pending booking request. The slot stays locked
  /// (it was already locked the moment the request came in), and the
  /// booking flips to confirmed so the customer sees it in their Activity tab.
  Future<void> acceptBooking(Booking booking) async {
    await updateBookingStatus(booking.id, BookingStatus.confirmed);
  }

  /// Artist/admin declines a pending booking request — this frees up the
  /// slot immediately so other customers can book that time again.
  Future<void> declineBooking(Booking booking) async {
    await cancelBooking(booking);
  }

  /// Artist/admin changes the date on a booking (e.g. the requested day
  /// doesn't work for them) without changing anything else — the customer
  /// will see the updated date next time they check My Bookings.
  Future<void> rescheduleBooking(String bookingId, DateTime newDate) async {
    await _db
        .collection(AppConstants.bookingsCollection)
        .doc(bookingId)
        .update({'date': newDate.toIso8601String()});
  }

  // ---------------- PRODUCTS (henna cones shop) ----------------

  Stream<List<Product>> streamProducts() {
    return _db
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Product.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addProduct(Product product) async {
    await _db.collection(AppConstants.productsCollection).add(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await _db
        .collection(AppConstants.productsCollection)
        .doc(product.id)
        .update(product.toMap());
  }

  Future<void> updateStock(String productId, int newStock) async {
    await _db
        .collection(AppConstants.productsCollection)
        .doc(productId)
        .update({'stock': newStock});
  }

  // ---------------- ORDERS (cone purchases) ----------------

  Future<String> createOrder(OrderModel order) async {
    final docRef =
        await _db.collection(AppConstants.ordersCollection).add(order.toMap());
    return docRef.id;
  }

  Stream<List<OrderModel>> streamUserOrders(String userId) {
    return _db
        .collection(AppConstants.ordersCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final orders = snap.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Stream<List<OrderModel>> streamAllOrders() {
    return _db
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({'status': status.name});
  }

  Future<void> markOrderPaid(String orderId, String paymentId) async {
    await _db.collection(AppConstants.ordersCollection).doc(orderId).update({
      'paymentStatus': PaymentStatus.paid.name,
      'razorpayPaymentId': paymentId,
    });
  }

  // ---------------- REVIEWS ----------------

  Future<void> submitReview(Review review) async {
    await _db.collection(AppConstants.reviewsCollection).add(review.toMap());
  }

  Future<void> deleteReview(String reviewId) async {
    await _db.collection(AppConstants.reviewsCollection).doc(reviewId).delete();
  }

  /// All reviews left for one service or product (e.g. to compute an average).
  Stream<List<Review>> streamReviewsForTarget(String targetId) {
    return _db
        .collection(AppConstants.reviewsCollection)
        .where('targetId', isEqualTo: targetId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Review.fromMap(d.data(), d.id)).toList());
  }

  /// General testimonials (not tied to one specific service/product) —
  /// typically typed in by the admin from WhatsApp/Instagram feedback, shown
  /// in a "What Customers Say" carousel on the Book tab.
  Stream<List<Review>> streamTestimonials() {
    return _db
        .collection(AppConstants.reviewsCollection)
        .where('targetType', isEqualTo: 'general')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Review.fromMap(d.data(), d.id)).toList());
  }

  /// Every review left anywhere — admin-added testimonials AND real
  /// customer reviews of specific services/products — shown together in
  /// the Our Work tab's "What Customers Say" section.
  Stream<List<Review>> streamAllReviews() {
    return _db
        .collection(AppConstants.reviewsCollection)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Review.fromMap(d.data(), d.id)).toList());
  }

  /// Whether the current user has already reviewed this specific booking/order,
  /// so the "Rate this" button can hide itself after a review is submitted.
  Future<bool> hasReviewedSource(String sourceId) async {
    final snap = await _db
        .collection(AppConstants.reviewsCollection)
        .where('sourceId', isEqualTo: sourceId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ---------------- PUSH NOTIFICATIONS ----------------

  /// Saves this device's FCM token onto the user's profile document so a
  /// Cloud Function can look it up and send them a push notification when
  /// their booking/order status changes.
  Future<void> saveFcmToken(String uid, String token) async {
    await _db.collection(AppConstants.usersCollection).doc(uid).update({
      'fcmToken': token,
    });
  }

  // ---------------- SHOP SETTINGS (location, radius, UPI) ----------------

  static const String _settingsDocPath = 'settings/shop';

  Future<ShopSettings> getShopSettings() async {
    final doc = await _db.doc(_settingsDocPath).get();
    if (!doc.exists) return ShopSettings();
    return ShopSettings.fromMap(doc.data() ?? {});
  }

  Stream<ShopSettings> streamShopSettings() {
    return _db.doc(_settingsDocPath).snapshots().map(
        (doc) => doc.exists ? ShopSettings.fromMap(doc.data() ?? {}) : ShopSettings());
  }

  Future<void> updateShopSettings(ShopSettings settings) async {
    await _db.doc(_settingsDocPath).set(settings.toMap());
  }

  // ---------------- OUR WORK FEED (photos, videos, blog posts) ----------------

  Stream<List<WorkPost>> streamWorkPosts() {
    return _db
        .collection(AppConstants.workPostsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => WorkPost.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addWorkPost(WorkPost post) async {
    await _db.collection(AppConstants.workPostsCollection).add(post.toMap());
  }

  Future<void> deleteWorkPost(String postId) async {
    await _db.collection(AppConstants.workPostsCollection).doc(postId).delete();
  }
}
