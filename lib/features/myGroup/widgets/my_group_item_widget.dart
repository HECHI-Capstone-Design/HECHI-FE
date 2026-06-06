// lib/features/myGroup/widgets/my_group_item_widget.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart'; 
import '../models/group_model.dart';
import '../../../app/routes.dart'; 

import '../../groupcommunity/controllers/group_controller.dart';
import '../../groupcommunity/bindings/group_binding.dart';
import '../../groupcommunity/pages/group_main_view.dart';

class MyGroupItemWidget extends StatelessWidget {
  final GroupModel group;

  const MyGroupItemWidget({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: GestureDetector(
        onTap: () async {
          print('🚀 [내 그룹 탭] 커뮤니티 이동 시동: ${group.title} (ID: ${group.id})');

          if (Get.isRegistered<GroupController>()) {
            await Get.delete<GroupController>(force: true);
          }

          Get.to(
                () => const GroupMainView(),
            arguments: group.id,
            binding: GroupBinding(),
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
                image: (group.backgroundImage != null && group.backgroundImage!.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(group.backgroundImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (group.backgroundImage == null || group.backgroundImage!.isEmpty)
                  ? const Icon(Icons.group, color: Colors.white54, size: 36)
                  : null,
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