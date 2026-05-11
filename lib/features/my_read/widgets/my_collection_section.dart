import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/app/routes.dart';
import '../../collection_detail/pages/collection_detail_view.dart';

class MyCollectionSection extends StatelessWidget {
  const MyCollectionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dummyCollections = [
      {
        "id": 1,
        "title": "우주소설",
        "type": "컬렉션",
        "username": "헤치헤치",
        "imageUrl": "https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=200&auto=format&fit=crop",
      },
      {
        "id": 2,
        "title": "요즘 핫한 소설",
        "type": "컬렉션",
        "username": "헤치헤치",
        "imageUrl": "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?q=80&w=200&auto=format&fit=crop",
      },
      {
        "id": 3,
        "title": "고전 문학 모음",
        "type": "컬렉션",
        "username": "헤치헤치",
        "imageUrl": "https://images.unsplash.com/photo-1474932430478-367dbb6832c1?q=80&w=200&auto=format&fit=crop",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 타이틀 영역
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            "좋아요한 컬렉션",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3F3F3F), // 보관함 타이틀과 동일한 색상
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 2. 가로 스크롤 카드 영역
        SizedBox(
          height: 210,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24.0), // 좌우 여백을 보관함과 동일하게 24로 맞춤
            scrollDirection: Axis.horizontal,
            itemCount: dummyCollections.length,
            itemBuilder: (context, index) {
              final item = dummyCollections[index];
              return GestureDetector(
                onTap: () => Get.to(() => const CollectionDetailView()),
                child: Container(
                  width: 140, // 카드를 조금 더 키워서 화면을 더 채우도록 함
                  margin: EdgeInsets.only(
                      right: (index == dummyCollections.length - 1) ? 0 : 16.0
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0), // 좀 더 둥글게
                        child: Image.network(
                          item["imageUrl"],
                          height: 140, width: 140, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 140, width: 140, color: const Color(0xFFF3F3F3),
                            child: Icon(Icons.image, color: Colors.grey[400]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item["title"],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${item["type"]} · ${item["username"]}",
                        style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E),
                        height: 1.2,),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        // 3. 내 컬렉션 전체보기 버튼
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: InkWell(
            onTap: () => Get.toNamed(Routes.collectionList),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11), // 상하 패딩 최적화
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, //
                children: const [
                  Text(
                    "내 컬렉션 전체보기",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4), // 텍스트와 아이콘 사이 간격
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}