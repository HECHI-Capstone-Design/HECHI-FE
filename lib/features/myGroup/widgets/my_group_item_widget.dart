// lib/features/myGroup/widgets/my_group_item_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart'; 
import '../models/group_model.dart';
import '../../../app/routes.dart'; 

// 💡 [추가] GroupJoinPage 클래스를 정상적으로 인식할 수 있도록 파일 경로 임포트!
import '../../group_join/pages/group_join_page.dart'; 
import '../../group_join/bindings/group_join_binding.dart';

class MyGroupItemWidget extends StatelessWidget {
  final GroupModel group;

  const MyGroupItemWidget({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () {
          print('📦 내 그룹 클릭됨: ${group.title} (ID: ${group.id})');
          Get.to(
            () => const GroupJoinPage(),
            arguments: group,
            binding: GroupJoinBinding(),
            transition: Transition.rightToLeft,
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[300], 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              group.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}