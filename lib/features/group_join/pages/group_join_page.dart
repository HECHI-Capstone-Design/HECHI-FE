// lib/features/group_join/pages/group_join_page.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/group_join_controller.dart';
import '../widgets/group_info_section.dart';
import '../widgets/book_item.dart';
import '../widgets/join_dialogs.dart';

class GroupJoinPage extends GetView<GroupJoinController> {
  const GroupJoinPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 투명하게 설정
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0, top: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () => Get.back(),
          ),
        ),
      ),
      body: Obx(() {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 💡 1~3번 영역을 하나의 거대한 회색 상자로 묶었습니다. (소개 위젯 전까지)
              Container(
                width: double.infinity,
                color: const Color.fromARGB(255, 190, 190, 190), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 180), 

                    // 2. 그룹 정보 섹션 (타이틀, 멤버수, 그룹장 등)
                    GroupInfoSection(
                      memberCount: controller.memberCount.value,
                      createdDate: controller.createdDate.value,
                      masterNickname: controller.masterNickname.value,
                      groupName: controller.groupName.value,
                    ),
                    
                    const SizedBox(height: 45),
                    
                    // 3. 💡 [수정] 그룹 가입하기 / 탈퇴하기 조건부 동적 분기 버튼 구역
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            if (controller.isAlreadyJoined.value) {
                              // 💡 이미 가입된 방이면 -> 탈퇴 프로세스 가동
                              controller.leaveGroup();
                            } else {
                              // 미가입 상태면 -> 기존 팝업 프로세스 가동
                              if (controller.isPublic.value) {
                                showPublicJoinDialog(context, controller);
                              } else {
                                showPrivateJoinDialog(context, controller);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            // 💡 이미 가입한 방이면 경고/탈퇴 느낌의 소프트 레드(#E26A6A), 미가입이면 초록색(#4DB56C)
                            backgroundColor: controller.isAlreadyJoined.value
                                ? const Color(0xffE26A6A)
                                : const Color(0xff4DB56C),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            // 💡 글자 타이틀도 가입 여부에 따라 동적 스위칭!
                            controller.isAlreadyJoined.value ? '그룹 탈퇴하기' : '그룹 가입하기',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // 버튼 아래쪽 배경 마무리를 위한 여백
                    const SizedBox(height: 35), 
                  ],
                ),
              ),

              // ------------------ 여기서부터 다시 흰색 배경 영역 ------------------

              // 4. 소개 섹션
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '소개',
                      style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controller.description.value,
                      style: const TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              
              // 5. 함께 읽고 있는 책 섹션 (공개 그룹이면서 책이 있을 때만 노출)
              if (controller.isPublic.value && controller.books.isNotEmpty) ...[
                const Divider(thickness: 1, color: Color(0xffE5E5E5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '함께 읽고 있는 책',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff555555)),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black.withOpacity(0.8)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 20),
                    itemCount: controller.books.length,
                    itemBuilder: (context, index) {
                      final book = controller.books[index];
                      return BookItem(
                        title: book['title'] ?? '',
                        imageUrl: book['image'] ?? '',
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}