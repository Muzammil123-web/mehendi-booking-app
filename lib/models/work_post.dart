enum WorkPostType { photo, video, blog }

/// A single item in the "Our Work" feed — a photo, a video/reel (linked
/// externally, e.g. an Instagram Reel or YouTube link), or a short blog-style
/// write-up. Kept separate from MehendiDesign, which is specifically the
/// pattern-picker shown during Bridal booking — this is the marketing/
/// portfolio feed customers browse to see the studio's work.
class WorkPost {
  final String id;
  final WorkPostType type;
  final String title;
  final String mediaUrl; // photo URL, or video/reel link (for type=video)
  final String body; // blog text, or a caption for photo/video
  final DateTime createdAt;

  WorkPost({
    required this.id,
    required this.type,
    required this.title,
    this.mediaUrl = '',
    this.body = '',
    required this.createdAt,
  });

  factory WorkPost.fromMap(Map<String, dynamic> map, String id) {
    return WorkPost(
      id: id,
      type: WorkPostType.values.firstWhere((e) => e.name == map['type'],
          orElse: () => WorkPostType.photo),
      title: map['title'] ?? '',
      mediaUrl: map['mediaUrl'] ?? '',
      body: map['body'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'mediaUrl': mediaUrl,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
