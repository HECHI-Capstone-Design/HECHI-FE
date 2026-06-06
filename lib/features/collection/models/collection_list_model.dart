class CollectionListItem {
  final String id;
  final String title;
  final String description;
  final String authorName;
  final String? authorProfileUrl;
  final List<String> tags;
  final List<String> bookCoverUrls;
  final int likeCount;
  final int bookCount;
  final bool isLiked;
  final bool isPublic;
  final bool hasBook;

  const CollectionListItem({
    required this.id,
    required this.title,
    required this.description,
    required this.authorName,
    this.authorProfileUrl,
    required this.tags,
    required this.bookCoverUrls,
    required this.likeCount,
    required this.bookCount,
    this.isLiked = false,
    this.isPublic = true,
    this.hasBook = false,
  });

  CollectionListItem copyWith({bool? isLiked}) {
    return CollectionListItem(
      id: id,
      title: title,
      description: description,
      authorName: authorName,
      authorProfileUrl: authorProfileUrl,
      tags: tags,
      bookCoverUrls: bookCoverUrls,
      likeCount: isLiked != null
          ? (isLiked ? likeCount + 1 : likeCount - 1)
          : likeCount,
      bookCount: bookCount,
      isLiked: isLiked ?? this.isLiked,
      isPublic: isPublic,
      hasBook: hasBook,
    );
  }

  factory CollectionListItem.fromJson(Map<String, dynamic> json) {
    return CollectionListItem(
      id: json['collectionId'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      authorName: json['userName'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      bookCoverUrls: List<String>.from(json['thumbnailCovers'] ?? []),
      likeCount: json['likeCount'] ?? 0,
      bookCount: json['bookCount'] ?? 0,
      isLiked: json['isLiked'] ?? false,
      isPublic: !(json['isPrivate'] ?? false),
      hasBook: json['hasBook'] ?? false,
    );
  }
}