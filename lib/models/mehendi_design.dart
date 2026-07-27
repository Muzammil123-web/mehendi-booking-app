/// A henna/mehendi design pattern the customer can pick before booking
/// (currently shown for services that require a design choice, e.g. Bridal).
class MehendiDesign {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final bool isActive;

  MehendiDesign({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.description = '',
    this.isActive = true,
  });

  factory MehendiDesign.fromMap(Map<String, dynamic> map, String id) {
    return MehendiDesign(
      id: id,
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'isActive': isActive,
    };
  }
}
