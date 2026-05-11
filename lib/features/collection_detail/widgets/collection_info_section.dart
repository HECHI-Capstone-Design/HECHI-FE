import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/collection_detail_controller.dart';

// 작성자 프사, 컬렉션 제목, 설명, #태그 들이 있는 영역입니다.
class CollectionInfoSection extends StatelessWidget {
  final CollectionDetailController controller;

  const CollectionInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 📝 [수정 꿀팁] 이 구역 전체의 여백 (좌우 24, 위 20, 아래 20)
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 작성자 프로필 & 수정하기 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(controller.creatorProfileImg),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    controller.creatorName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF3F3F3F)),
                  ),
                ],
              ),
              // 내 컬렉션일 때만 '수정하기' 버튼 노출
              if (controller.isMine.value)
                OutlinedButton(
                  onPressed: () {}, // 나중에 수정 페이지 연결
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                    side: const BorderSide(color: Color(0xFF89C99C)), // 테두리 색상
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text("수정하기", style: TextStyle(color: Color(0xFF4DB56C), fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. 컬렉션 제목
          Text(
            controller.collectionTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),

          // 3. 컬렉션 설명
          Text(
            controller.collectionDesc,
            style: const TextStyle(fontSize: 15, color: Color(0xFF555555), height: 1.4),
          ),
          const SizedBox(height: 16),

          // 4. 태그 리스트 (#소설, #인생책)
          Wrap(
            spacing: 8, // 태그 사이 가로 간격
            runSpacing: 8, // 태그 사이 세로 간격
            children: controller.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3), // 회색 알약 배경
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(tag, style: const TextStyle(fontSize: 13, color: Color(0xFF717171))),
            )).toList(),
          ),
        ],
      ),
    );
  }
}