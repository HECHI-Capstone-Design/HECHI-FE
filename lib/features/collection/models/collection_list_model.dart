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
      likeCount: isLiked == true ? likeCount + 1 : likeCount,
      bookCount: bookCount,
      isLiked: isLiked ?? this.isLiked,
      isPublic: isPublic,
    );
  }
}

// TODO: Replace dummy data with API response
final List<CollectionListItem> dummyCollections = [
  CollectionListItem(
    id: '1',
    title: '이런 소설만 읽을 수 있다면',
    description: '조금 더 행복하게 살 수 있을 거 같아 (소장 도서로만 컬렉션을 꾸립니다)',
    authorName: 'Josee',
    tags: ['#소설', '#인생책'],
    bookCoverUrls: [
      'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=200',
      'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=200',
      'https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=200',
      'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=200',
      'https://images.unsplash.com/photo-1495640388908-05fa85288e61?w=200',
    ],
    likeCount: 2641,
    bookCount: 7,
    isLiked: false,
  ),
  CollectionListItem(
    id: '2',
    title: '한번에 읽어버린 책들',
    description: '손에서 놓을 수가 없었던 책들을 모아봤어요',
    authorName: 'Josee',
    tags: ['#몰입감있는', '#한번에읽는'],
    bookCoverUrls: [],
    likeCount: 1823,
    bookCount: 5,
    isLiked: true,
  ),
  CollectionListItem(
    id: '3',
    title: '자기 전에 읽기 좋은 에세이',
    description: '마음이 편안해지는 에세이 모음',
    authorName: 'bookworm',
    tags: ['#에세이', '#잠들기전에읽는', '#힐링'],
    bookCoverUrls: [],
    likeCount: 987,
    bookCount: 12,
    isLiked: false,
  ),
];