import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';

class MemberProfileDialog extends GetView<GroupController> {
  final Map<String, dynamic> member;
  const MemberProfileDialog({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF4EB56D);

    // 소수점을 떼고 0~100 정수로 변환하는 로직은 일회성 계산이므로 
    // Obx 내부가 아니라 빌드 시점에 미리 계산해두는 것이 가독성과 성능에 훨씬 좋습니다.
    final double rawProgress = double.tryParse(member["progress"]?.toString() ?? "0.0") ?? 0.0;
    final int percent = rawProgress.clamp(0, 100).toInt();

    return Dialog(
      backgroundColor: Colors.white, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Obx(() {
          // 다이얼로그 전체를 Obx로 감싸서 controller.isLeader.value의 변화를 
          // 실시간으로 감시하고 하단의 강제 탈퇴 버튼 노출 여부를 동적으로 결정합니다.
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(member["nickname"] ?? "그룹원", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  TextButton(onPressed: () => Get.back(), child: const Text("취소", style: TextStyle(color: brandColor))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("미션책 진행률", style: TextStyle(color: Colors.black54)),
                  Text(
                    "$percent%", 
                    style: const TextStyle(color: brandColor, fontWeight: FontWeight.normal)
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFEAEAEA)),
              
              // 이제 controller.isLeader의 Rx 변수가 변경되면 
              // 이 버튼의 노출 여부가 실시간으로 UI에 업데이트됩니다.
              if (controller.isLeader.value && member["isLeader"] != true)
                InkWell(
                  onTap: () {
                    controller.kickMember(member["nickname"] ?? "");
                    Get.back();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text("강제 탈퇴", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                )
            ],
          );
        }),
      ),
    );
  }
}