import 'package:hechi/app/colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/groupcommunity/widgets/member_profile_dialog.dart';
import 'package:hechi/features/groupcommunity/pages/group_post_list_view.dart';

class GroupMainView extends GetView<GroupController> {
  const GroupMainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const unifiedGreen = AppColors.primaryLight;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
          controller.groupName.value.isEmpty ? "로딩 중..." : controller.groupName.value,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        )),
        centerTitle: true,
        actions: [
          Obx(() {
            final bool hasBook = controller.currentMissionBookTitle.value.isNotEmpty &&
                controller.currentMissionBookTitle.value != "미설정";
            return IconButton(
              icon: Icon(
                hasBook ? Icons.menu_book_rounded : Icons.bookmark_border_rounded,
                color: hasBook ? unifiedGreen : Colors.grey,
                size: 24,
              ),
              onPressed: () {
                if (hasBook) {
                  Get.toNamed('/book_detail_page', arguments: controller.currentMissionBookId.value);
                } else {
                  Get.snackbar("알림", "현재 선정된 미션책이 없습니다. 메뉴에서 미션책을 변경해보세요!");
                }
              },
            );
          }),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black, size: 28),
            onPressed: () => Get.toNamed('/group/menu'),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.groupName.value.isEmpty) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(unifiedGreen)));
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchAllDataFromAPI(),
          color: unifiedGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Obx(() {
                    final title = controller.currentMissionBookTitle.value;
                    final bool hasBook = title.isNotEmpty && title != "미설정";

                    return GestureDetector(
                      onTap: () {
                        if (hasBook) {
                          Get.toNamed('/book_detail_page', arguments: controller.currentMissionBookId.value);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.textDark,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: controller.currentMissionBookCover.value.isEmpty || controller.currentMissionBookCover.value == "미설정"
                                    ? Container(color: AppColors.textDark)
                                    : Image.network(controller.currentMissionBookCover.value, fit: BoxFit.cover),
                              ),
                              Positioned.fill(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                                  child: Container(color: Colors.black.withOpacity(0.3)),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 68,
                                      height: 98,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: Colors.grey.shade800,
                                        border: Border.all(color: AppColors.border, width: 0.5),
                                        image: hasBook ? DecorationImage(
                                          image: NetworkImage(controller.currentMissionBookCover.value),
                                          fit: BoxFit.cover,
                                        ) : null,
                                      ),
                                      child: hasBook ? null : const Icon(Icons.bookmark, color: Colors.white24, size: 28),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            hasBook ? title : "미설정",
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            hasBook ? controller.currentMissionBookAuthor.value : "미설정 상태",
                                            style: const TextStyle(fontSize: 13, color: Colors.white70),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        final name = controller.groupName.value.isEmpty ? "그룹" : controller.groupName.value;
                        return Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(
                                text: " 미션 독서 진행률",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 6),
                      Obx(() {
                        final int percent = (controller.groupAverageProgress.value * 100).clamp(0, 100).toInt();
                        return Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: controller.groupAverageProgress.value,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: const AlwaysStoppedAnimation<Color>(unifiedGreen),
                                  minHeight: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 36,
                              child: Text(
                                "$percent%",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),
                      const Text("나의 미션 독서 진행률", style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Obx(() {
                        final int percent = (controller.myProgress.value * 100).clamp(0, 100).toInt();
                        return Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: controller.myProgress.value,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: const AlwaysStoppedAnimation<Color>(unifiedGreen),
                                  minHeight: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 36,
                              child: Text(
                                "$percent%",
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Obx(() {
                      final List<dynamic> list = controller.memberList;

                      if (list.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                                "그룹에 참여 중인 멤버가 없습니다.",
                                style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)
                            ),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 4,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final member = list[index];
                          return GestureDetector(
                            onTap: () => Get.dialog(MemberProfileDialog(member: member)),
                            child: Column(
                              children: [
                                const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: unifiedGreen,
                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  member["nickname"] ?? "그룹원",
                                  style: const TextStyle(fontSize: 10, color: Colors.black54, overflow: TextOverflow.ellipsis),
                                )
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Obx(() {
                    final bool hasAnn = controller.announcements.isNotEmpty;
                    final String displayContent = hasAnn
                        ? (controller.announcements.first["content"]?.toString() ?? "새로운 공지사항이 있습니다.")
                        : "등록된 공지사항이 없습니다. 새로운 소식을 확인해보세요!";

                    return InkWell(
                      onTap: () => Get.to(() => const GroupAnnouncementListView()),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.backgroundGrey, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.volume_up, color: unifiedGreen, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                displayContent,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: hasAnn ? Colors.black87 : Colors.grey,
                                    fontWeight: hasAnn ? FontWeight.normal : FontWeight.w500
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey)
                          ],
                        ),
                      ),
                    );
                  }),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        final title = controller.currentMissionBookTitle.value;
                        final isSet = title.isNotEmpty && title != "미설정";
                        return Padding(
                          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                          child: Text(
                              isSet ? "[$title] 게시판" : "[미션책 제목] 게시판",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)
                          ),
                        );
                      }),

                      Obx(() {
                        final title = controller.currentMissionBookTitle.value;
                        if (title.isEmpty || title == "미설정") {
                          return _buildOpenBoardTile("미션책을 선정해주세요", () {});
                        }

                        return _buildOpenBoardTile(
                            "신간부터 읽어보자 하고 도전했는데요...",
                                () async {
                              final String currentBookIdStr = controller.currentMissionBookId.value.toString();
                              await controller.fetchFilteredBookBoard(currentBookIdStr, true);
                              Get.to(() => const GroupPostListView(isMissionBoard: true));
                            }
                        );
                      }),

                      const SizedBox(height: 20),

                      const Padding(
                        padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                        child: Text("자유게시판", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                      ),

                      _buildOpenBoardTile(
                          "여러분들이 자유롭게 글을 쓰고 공유하는 공간입니다.",
                              () async {
                            await controller.fetchAllDataFromAPI();
                            Get.to(() => const GroupPostListView(isMissionBoard: false));
                          }
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOpenBoardTile(String subtitle, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(12)
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class GroupAnnouncementListView extends GetView<GroupController> {
  const GroupAnnouncementListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const brandColor = AppColors.primaryLight;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("공지사항 게시판", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.announcements.isEmpty) {
          return const Center(child: Text("등록된 공지사항이 없습니다.", style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          itemCount: controller.announcements.length,
          separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) {
            final ann = controller.announcements[index];
            return Obx(() {
              final bool isPinned = ann["isPinned"]?.value ?? false;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: isPinned ? AppColors.primarySurface : Colors.white,
                leading: Icon(
                    Icons.campaign,
                    color: isPinned ? brandColor : Colors.grey,
                    size: 24
                ),
                title: Row(
                  children: [
                    if (isPinned)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: brandColor, borderRadius: BorderRadius.circular(4)),
                        child: const Text("고정", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    Expanded(
                      child: Text(
                          ann["title"] ?? "공지사항",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isPinned ? brandColor : Colors.black87)
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(ann["content"] ?? "", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onPressed: () => _showAnnouncementOptions(context, ann),
                ),
              );
            });
          },
        );
      }),
    );
  }

  void _showAnnouncementOptions(BuildContext context, Map<String, dynamic> ann) {
    final bool isPinned = ann["isPinned"]?.value ?? false;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("공지 설정 옵션", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(),
            if (controller.isLeader.value) ...[
              ListTile(
                leading: Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: Colors.blue),
                title: Text(isPinned ? "상단 고정 해제 (글 밑으로 내리기)" : "가장 상단에 올리기 (핀 고정)"),
                onTap: () async {
                  Get.back();

                  await controller.togglePinAnnouncement(ann);
                  Get.snackbar("알림", isPinned ? "공지 고정이 해제되었습니다." : "공지가 최상단에 고정되었습니다.");
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("공지 삭제", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Get.back();
                  controller.deleteAnnouncement(ann);
                  Get.snackbar("알림", "공지사항이 삭제되었습니다.");
                },
              )
            ] else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text("권한이 없습니다 (방장 전용 메뉴)", style: TextStyle(color: Colors.grey, fontSize: 13)),
              )
            ]
          ],
        ),
      ),
    );
  }
}