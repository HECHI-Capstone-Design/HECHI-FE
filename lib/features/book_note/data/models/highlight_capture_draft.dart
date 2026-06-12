class HighlightCaptureDraft {
  const HighlightCaptureDraft({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.page,
    required this.imagePath,
    required this.createdAt,
  });

  final String id;
  final int bookId;
  final String bookTitle;
  final int page;
  final String imagePath;
  final String createdAt;

  factory HighlightCaptureDraft.fromJson(Map<String, dynamic> json) {
    return HighlightCaptureDraft(
      id: json['id']?.toString() ?? '',
      bookId: (json['bookId'] as num?)?.toInt() ?? 0,
      bookTitle: json['bookTitle']?.toString() ?? '',
      page: (json['page'] as num?)?.toInt() ?? 0,
      imagePath: json['imagePath']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'page': page,
      'imagePath': imagePath,
      'createdAt': createdAt,
    };
  }
}
