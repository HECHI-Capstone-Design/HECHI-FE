import 'package:flutter/material.dart';
import '../models/group_model.dart';

class RecommendedGroupItemWidget extends StatelessWidget {
  final GroupModel group;
  final bool showDescription;

  const RecommendedGroupItemWidget({
    Key? key,
    required this.group,
    this.showDescription = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 이미지 & 프로필 영역
          Stack(
            children: [
              Container(
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFB0BEC5), // 임시 배경 (청회색)
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 20, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      group.authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          // 하단 텍스트 영역
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (showDescription && group.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    group.description!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}