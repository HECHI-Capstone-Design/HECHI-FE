import 'package:flutter/material.dart';
import '../controllers/collection_detail_controller.dart';

// 피그마 상단에 책 표지 여러 장이 배경처럼 깔려있는 영역입니다.
class CollectionTopImages extends StatelessWidget {
  final CollectionDetailController controller;

  const CollectionTopImages({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // 📝 [수정 꿀팁] 상단 배경 이미지들의 전체 높이입니다.
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, // 가로로 스크롤 되게 만들기
        itemCount: controller.topCoverImages.length,
        itemBuilder: (context, index) {
          return Container(
            // 📝 [수정 꿀팁] 이미지 1장당 너비입니다. (화면 너비의 1/3 정도로 설정)
            width: MediaQuery.of(context).size.width * 0.35,
            margin: const EdgeInsets.only(right: 8), // 이미지 사이 간격
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(controller.topCoverImages[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}