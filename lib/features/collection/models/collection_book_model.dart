class CollectionBook {
  final String id;
  final String title;
  final String author;
  final String? coverUrl;

  const CollectionBook({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
  });
}