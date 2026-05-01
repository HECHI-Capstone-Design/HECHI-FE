class CollectionTag {
  final String label;
  final String category;

  const CollectionTag({required this.label, required this.category});
}

class TagCategory {
  final String name;
  final List<CollectionTag> tags;

  const TagCategory({required this.name, required this.tags});
}

// TODO: Replace dummy data with API response
final List<TagCategory> allTagCategories = [
  TagCategory(
    name: '장르',
    tags: [
      CollectionTag(label: '#소설', category: '장르'),
      CollectionTag(label: '#시', category: '장르'),
      CollectionTag(label: '#에세이', category: '장르'),
      CollectionTag(label: '#만화', category: '장르'),
      CollectionTag(label: '#추리', category: '장르'),
      CollectionTag(label: '#스릴러/공포', category: '장르'),
      CollectionTag(label: '#SF', category: '장르'),
      CollectionTag(label: '#판타지', category: '장르'),
      CollectionTag(label: '#로맨스', category: '장르'),
      CollectionTag(label: '#액션', category: '장르'),
      CollectionTag(label: '#역사', category: '장르'),
      CollectionTag(label: '#과학', category: '장르'),
      CollectionTag(label: '#인문', category: '장르'),
      CollectionTag(label: '#철학', category: '장르'),
      CollectionTag(label: '#사회/정치', category: '장르'),
      CollectionTag(label: '#경제/경영', category: '장르'),
      CollectionTag(label: '#자기계발', category: '장르'),
      CollectionTag(label: '#예술', category: '장르'),
      CollectionTag(label: '#여행', category: '장르'),
      CollectionTag(label: '#취미', category: '장르'),
      CollectionTag(label: '#코미디', category: '장르'),
    ],
  ),
  TagCategory(
    name: '감정',
    tags: [
      CollectionTag(label: '#힐링', category: '감정'),
      CollectionTag(label: '#감동', category: '감정'),
      CollectionTag(label: '#눈물나는', category: '감정'),
      CollectionTag(label: '#위로되는', category: '감정'),
      CollectionTag(label: '#여운이남는', category: '감정'),
    ],
  ),
  TagCategory(
    name: '분위기',
    tags: [
      CollectionTag(label: '#잔잔한', category: '분위기'),
      CollectionTag(label: '#어두운', category: '분위기'),
      CollectionTag(label: '#긴장감있는', category: '분위기'),
      CollectionTag(label: '#몰입감있는', category: '분위기'),
    ],
  ),
  TagCategory(
    name: '상황',
    tags: [
      CollectionTag(label: '#잠들기전에읽는', category: '상황'),
      CollectionTag(label: '#주말에읽기좋은', category: '상황'),
      CollectionTag(label: '#카페에서읽기좋은', category: '상황'),
      CollectionTag(label: '#여행할때읽기좋은', category: '상황'),
    ],
  ),
  TagCategory(
    name: '독서스타일',
    tags: [
      CollectionTag(label: '#가볍게읽기좋은', category: '독서스타일'),
      CollectionTag(label: '#한번에읽는', category: '독서스타일'),
      CollectionTag(label: '#천천히읽는', category: '독서스타일'),
      CollectionTag(label: '#인생책', category: '독서스타일'),
    ],
  ),
  TagCategory(
    name: '난이도',
    tags: [
      CollectionTag(label: '#초보추천', category: '난이도'),
      CollectionTag(label: '#생각이많아지는', category: '난이도'),
      CollectionTag(label: '#지식이쌓이는', category: '난이도'),
    ],
  ),
];