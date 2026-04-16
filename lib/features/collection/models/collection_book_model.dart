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

// TODO: Replace dummy data with API response
final List<CollectionBook> dummySearchBooks = [
  CollectionBook(id: '1', title: '혼모노', author: '하야시 마리코', coverUrl: null),
  CollectionBook(id: '2', title: '이런 소설만 읽을 수 있다면', author: 'Josee', coverUrl: null),
  CollectionBook(id: '3', title: '채식주의자', author: '한강', coverUrl: null),
  CollectionBook(id: '4', title: '82년생 김지영', author: '조남주', coverUrl: null),
];