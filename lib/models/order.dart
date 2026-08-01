import 'booking.dart'; // reuse PaymentMethod / PaymentStatus enums

enum OrderStatus { placed, packed, shipped, delivered, cancelled }

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final List<CartItemData> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String? razorpayPaymentId;
  final OrderStatus status;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    this.razorpayPaymentId,
    this.status = OrderStatus.placed,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? '',
      deliveryLat: map['deliveryLat']?.toDouble(),
      deliveryLng: map['deliveryLng']?.toDouble(),
      items: (map['items'] as List<dynamic>? ?? [])
          .map((i) => CartItemData.fromMap(i as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
          (e) => e.name == map['paymentMethod'],
          orElse: () => PaymentMethod.cod),
      paymentStatus: PaymentStatus.values.firstWhere(
          (e) => e.name == map['paymentStatus'],
          orElse: () => PaymentStatus.pending),
      razorpayPaymentId: map['razorpayPaymentId'],
      status: OrderStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => OrderStatus.placed),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'deliveryAddress': deliveryAddress,
      'deliveryLat': deliveryLat,
      'deliveryLng': deliveryLng,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'paymentMethod': paymentMethod.name,
      'paymentStatus': paymentStatus.name,
      'razorpayPaymentId': razorpayPaymentId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Lightweight snapshot of a cart item as stored inside an order document
/// (kept separate from CartItem, which holds a live Product reference).
class CartItemData {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  CartItemData({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory CartItemData.fromMap(Map<String, dynamic> map) {
    return CartItemData(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }
}
