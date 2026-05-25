// lib/features/myGroup/widgets/recommended_group_item_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/group_model.dart';

// 💡 패키지 절대 경로를 지정하여 컴파일러 오류를 방지합니다.
import 'package:hechi/features/group_join/pages/group_join_page.dart';
import 'package:hechi/features/group_join/bindings/group_join_binding.dart';

class RecommendedGroupItemWidget extends StatelessWidget {
  final GroupModel group;
  final bool showDescription;

  const RecommendedGroupItemWidget({
    Key? key,
    required this.group,
    this.showDescription = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        print('👉 그룹 카드 클릭됨: ${group.title}');
        Get.to(
          () => GroupJoinPage(),
          binding: GroupJoinBinding(),
          arguments: group,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffE5E5E5), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11), // 테두리 안쪽 잘림 방지
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 상단: 배경 영역 (프로필 아이콘 + 닉네임 오버레이)
              Container(
                width: double.infinity,
                height: 120, // 사진 속 상단 배경 높이
                color: Colors.grey[300], // TODO: 나중에 배경 이미지 넣으실 때 decorationImage로 변경 가능합니다.
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end, // 프로필을 하단에 정렬
                  children: [
                    // 프로필 원형 아이콘
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, color: Colors.grey[400], size: 20),
                    ),
                    const SizedBox(width: 8),
                    // 닉네임 텍스트
                    Text(
                      group.authorName.isNotEmpty ? group.authorName : '달해',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2.0,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 2. 하단: 정보 영역 (그룹명 + 설명)
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 그룹 타이틀
                    Text(
                      group.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff333333),
                      ),
                    ),
                    // 설명글(showDescription이 true이거나 메인 추천 탭일 때 노출)
                    if (showDescription && group.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        group.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}