import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/groupcommunity/widgets/member_profile_dialog.dart';

class GroupMemberListView extends GetView<GroupController> {
  const GroupMemberListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    final filteredMembers = <Map<String, dynamic>>[].obs;
    filteredMembers.addAll(controller.memberList);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("멤버 보기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                filteredMembers.assignAll(controller.memberList.where(
                  (m) => m["nickname"].toString().contains(value)
                ).toList());
              },
              decoration: InputDecoration(
                hintText: "검색",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.backgroundGrey, borderRadius: BorderRadius.circular(16)),
                child: Obx(() => GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 4,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
                    return GestureDetector(
                      onTap: () => Get.dialog(MemberProfileDialog(member: member)),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primaryLight,
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member["nickname"] ?? "그룹원",
                            style: const TextStyle(fontSize: 10, color: Colors.black87, overflow: TextOverflow.ellipsis),
                          )
                        ],
                      ),
                    );
                  },
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}