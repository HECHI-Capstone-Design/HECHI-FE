import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/collection_detail_controller.dart';

// "작품들 O개" 텍스트와 책들이 3줄 격자(Grid)로 나열되는 영역입니다.
class CollectionBookGrid extends StatelessWidget {
  final CollectionDetailController controller;

  const CollectionBookGrid({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. "작품들 N" 헤더
          Row(
            children: [
              const Text("작품들", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3F3F3F))),
              const SizedBox(width: 8),
              Obx(() => Text(
                "${controller.books.length}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9E9E9E)),
              )),
            ],
          ),
          const SizedBox(height: 20),

          // 2. 책 표지 3칸 격자(Grid) 배치
          Obx(() {
            return GridView.builder(
              shrinkWrap: true, // 안쪽 리스트가 스크롤 에러를 일으키지 않게 꽉 잡아줌
              physics: const NeverScrollableScrollPhysics(), // 바깥 화면 스크롤 사용
              itemCount: controller.books.length,
              // 📝 [수정 꿀팁] 피그마처럼 가로로 3권씩 보여주기 위한 세팅!
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 1줄에 3권씩
                crossAxisSpacing: 12, // 가로 간격
                mainAxisSpacing: 20, // 세로 간격
                childAspectRatio: 0.55, // 책 표지(세로로 김) + 글자 공간 확보
              ),
              itemBuilder: (context, index) {
                final book = controller.books[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 책 표지 이미지
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          // 그림자를 넣어서 피그마처럼 살짝 띄워줍니다.
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            book['cover']!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 책 제목 (길면 ... 처리)
                    Text(
                      book['title']!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3F3F3F)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // 작가 이름
                    Text(
                      book['author']!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            );
          }),
        ],
      ),
    );
  }
}