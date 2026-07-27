/// Single-document settings for the business itself (not a specific
/// customer): where the shop is located, how far the artist is willing to
/// travel for home-visit bookings, and the UPI ID customers can pay to
/// directly (PhonePe / Google Pay / Paytm / any UPI app).
class ShopSettings {
  final double? latitude;
  final double? longitude;
  final double serviceRadiusKm;
  final String upiId;
  final String businessName;
  final String instagramHandle;
  final String phoneNumber;
  final String contactEmail;

  ShopSettings({
    this.latitude,
    this.longitude,
    this.serviceRadiusKm = 10,
    this.upiId = '',
    this.businessName = 'Mehendi Studio',
    this.instagramHandle = '',
    this.phoneNumber = '',
    this.contactEmail = '',
  });

  bool get hasLocation => latitude != null && longitude != null;

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      serviceRadiusKm: (map['serviceRadiusKm'] ?? 10).toDouble(),
      upiId: map['upiId'] ?? '',
      businessName: map['businessName'] ?? 'Mehendi Studio',
      instagramHandle: map['instagramHandle'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'serviceRadiusKm': serviceRadiusKm,
      'upiId': upiId,
      'businessName': businessName,
      'instagramHandle': instagramHandle,
      'phoneNumber': phoneNumber,
      'contactEmail': contactEmail,
    };
  }
}
