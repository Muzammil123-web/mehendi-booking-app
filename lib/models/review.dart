enum ReviewTargetType { service, product, general }

/// Where a review/testimonial came from — reviews left inside the app after
/// a real booking/order are 'app'; anything else was typed in manually by
/// the admin after receiving praise elsewhere, and is labeled honestly in
/// the UI so customers know it wasn't verified through an in-app purchase.
enum ReviewSource { app, whatsapp, instagram, other }

/// A customer's rating + comment — either left after a completed booking or
/// delivered order (targetType service/product), or a general testimonial
/// the admin typed in from WhatsApp/Instagram feedback (targetType general).
/// Stored in a top-level 'reviews' collection so average ratings can be
/// computed per service/product with a single query.
class Review {
  final String id;
  final String userId;
  final String userName;
  final ReviewTargetType targetType;
  final String targetId; // serviceId, productId, or '' for general
  final String targetName;
  final String sourceId; // bookingId/orderId this review is tied to, or a generated id
  final ReviewSource source;
  final double rating; // 1-5
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.sourceId,
    this.source = ReviewSource.app,
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      targetType: ReviewTargetType.values.firstWhere(
          (e) => e.name == map['targetType'],
          orElse: () => ReviewTargetType.service),
      targetId: map['targetId'] ?? '',
      targetName: map['targetName'] ?? '',
      sourceId: map['sourceId'] ?? '',
      source: ReviewSource.values.firstWhere(
          (e) => e.name == map['source'],
          orElse: () => ReviewSource.app),
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'targetType': targetType.name,
      'targetId': targetId,
      'targetName': targetName,
      'sourceId': sourceId,
      'source': source.name,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
