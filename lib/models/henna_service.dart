/// Represents a bookable mehendi/henna service (e.g. Bridal, Arabic, Simple)
class HennaService {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String imageUrl;
  final bool isActive;
  final bool requiresDesignSelection;

  HennaService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.imageUrl,
    this.isActive = true,
    this.requiresDesignSelection = false,
  });

  factory HennaService.fromMap(Map<String, dynamic> map, String id) {
    return HennaService(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      durationMinutes: map['durationMinutes'] ?? 60,
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      // Fall back to name-sniffing for services saved before this field existed.
      requiresDesignSelection: map['requiresDesignSelection'] ??
          (map['name'] ?? '').toString().toLowerCase().contains('bridal'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'requiresDesignSelection': requiresDesignSelection,
    };
  }
}
