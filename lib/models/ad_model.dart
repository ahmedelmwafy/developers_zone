
class AdModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String? targetUrl;
  final bool active;
  final String type; // splash, home

  AdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.targetUrl,
    this.active = true,
    required this.type,
  });

  factory AdModel.fromMap(Map<String, dynamic> data, String docId) {
    return AdModel(
      id: docId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      targetUrl: data['targetUrl'],
      active: data['active'] ?? true,
      type: data['type'] ?? 'home',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'targetUrl': targetUrl,
      'active': active,
      'type': type,
    };
  }
}
