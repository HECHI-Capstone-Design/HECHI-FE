class CollectionTag {
  final int? tagId;
  final String label;
  final String category;

  const CollectionTag({
    this.tagId,
    required this.label,
    required this.category,
  });

  factory CollectionTag.fromJson(Map<String, dynamic> json) {
    return CollectionTag(
      tagId: json['tagId'],
      label: json['name'] ?? '',
      category: json['categoryName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'tagId': tagId,
    'name': label,
    'categoryName': category,
  };
}

class TagCategory {
  final int? categoryId;
  final String name;
  final String? code;
  List<CollectionTag> tags;

  TagCategory({
    this.categoryId,
    required this.name,
    this.code,
    this.tags = const [],
  });

  factory TagCategory.fromJson(Map<String, dynamic> json) {
    return TagCategory(
      categoryId: json['categoryId'],
      name: json['name'] ?? '',
      code: json['code'],
    );
  }
}