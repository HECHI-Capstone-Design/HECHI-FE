// lib/features/myGroup/widgets/recommended_group_item_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/group_model.dart';

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
          borderRadius: BorderRadius.circular(11),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 120,
                color: Colors.grey[300],
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, color: Colors.grey[400], size: 18),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          group.leaderName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 4.0,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff333333),
                      ),
                    ),
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