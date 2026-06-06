import 'dart:convert';
import 'dart:io';
import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/groupcommunity/pages/group_report_views.dart';
import 'package:hechi/features/myGroup/controllers/my_group_controller.dart';
import 'package:hechi/features/search/data/book_model.dart';

class GroupMenuView extends StatelessWidget {
  const GroupMenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GroupController controller = Get.find<GroupController>();
    const brandMainGreen = AppColors.primary; 

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("그룹 메뉴", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.collections_bookmark, color: Colors.black87),
            title: const Text("미션 책 보관함"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Get.toNamed('/group/mission-history'),
          ),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.black87),
            title: const Text("멤버 보기"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => Get.toNamed('/group/members'),
          ),

          Obx(() {
            if (!controller.isLeader.value) return const SizedBox.shrink();
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.add_photo_alternate_outlined, color: Colors.black87),
                  title: const Text("프로필 사진 변경"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _changeGroupProfileImage(controller),
                ),
                ListTile(
                  leading: const Icon(Icons.campaign, color: Colors.black87),
                  title: const Text("공지사항 작성하기"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Get.toNamed('/group/announcement/write'),
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book, color: Colors.black87),
                  title: const Text("미션책 변경"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showChangeMissionBookSheet(brandMainGreen, controller),
                ),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.black87),
                  title: const Text("신고함"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => Get.to(() => const GroupReportListView()),
                ),
              ],
            );
          }),
          
          const Spacer(),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () => _showCustomConfirmDialog(context, controller),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Obx(() => Text(
                        controller.isLeader.value ? "그룹 삭제" : "그룹 탈퇴",
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                      )),
                ),
              ),
            ),
          )
        ],
      ),
      ),
    );
  }

  void _showCustomConfirmDialog(BuildContext context, GroupController controller) {
    final bool isLeader = controller.isLeader.value;
    final String titleText = isLeader ? "그룹 삭제" : "그룹 탈퇴";
    final String bodyText = isLeader ? "정말 그룹을 삭제하시겠습니까?" : "정말 그룹을 탈퇴하시겠습니까?";

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 20.0, left: 16.0, right: 16.0),
                  child: Column(
                    children: [
                      Text(
                        titleText,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bodyText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 0.5,
                  color: AppColors.border,
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(14)),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            
                            if (isLeader) {
                              bool success = await controller.deleteGroup();
                              if (success) {
                                Get.back(); 
                                Get.offAllNamed('/home');
                                Get.snackbar("삭제 완료", "그룹이 성공적으로 삭제되었습니다.");
                              } else {
                                Get.snackbar("오류", "그룹 삭제 요청 처리에 실패했습니다.");
                              }
                            } else {
                              bool success = await controller.leaveGroup();
                              if (success) {
                                Get.back(); 
                                Get.offAllNamed('/home');
                                Get.snackbar("탈퇴 완료", "그룹에서 성공적으로 탈퇴되었습니다.");
                              } else {
                                Get.snackbar("오류", "그룹 탈퇴 요청 처리에 실패했습니다.");
                              }
                            }
                          },
                          child: const Text(
                            "예",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 0.5,
                        color: AppColors.border,
                      ),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(bottomRight: Radius.circular(14)),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            "아니오",
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangeMissionBookSheet(Color brandColor, GroupController controller) {
    final searchInputController = TextEditingController();
    controller.searchedBooksResult.clear();

    Get.to(
      Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Get.back()),
          title: const Text("미션 책 변경하기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
          centerTitle: true,
        ),
        body: SafeArea(
          top: false,
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchInputController,
                onSubmitted: (val) => controller.searchBooksFromAPI(val),
                decoration: InputDecoration(
                  hintText: "새 미션 도서 검색 후 엔터",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Text("검색 결과 선택", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const Divider(),
            Expanded(
              child: Obx(() {
                if (controller.isSearching.value) return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(brandColor)));
                if (controller.searchedBooksResult.isEmpty) {
                  return const Center(child: Text("변경할 새 도서를 검색해 주세요.", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: controller.searchedBooksResult.length,
                  itemBuilder: (context, index) {
                    final Book book = controller.searchedBooksResult[index];
                    
                    final String title = book.title;
                    final String author = book.authorString;
                    final String coverUrl = book.thumbnail ?? "https://images.unsplash.com/photo-1495640388908-05fa85288e61?q=80&w=200";
                    
                    final String targetIsbn = book.isbn ?? "";

                    return ListTile(
                      leading: Container(
                        width: 40, height: 60,
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                        child: Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image)),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(author, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: const Icon(Icons.check_circle_outline, color: Colors.grey),
                      onTap: () async {
                        if (targetIsbn.isEmpty) {
                          Get.snackbar("알림", "해당 도서는 ISBN 정보가 식별되지 않아 미션책으로 등록할 수 없습니다.");
                          return;
                        }
                        
                        bool isSuccess = await controller.changeMissionBook(targetIsbn);
                        Get.back(); 
                        if (isSuccess) {
                          Get.snackbar("성공", "미션책이 변경 되었습니다.");
                        } else {
                          Get.snackbar("오류", "미션책 변경에 실패했습니다.");
                        }
                      },
                    );
                  },
                );
              }),
            ),
          ],
          ),
          ),
        ),
    );
  }

  Future<void> _changeGroupProfileImage(GroupController controller) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;

      Get.snackbar("업로드 중", "사진 업로드 중...", duration: const Duration(seconds: 2));

      final token = GetStorage().read('access_token') as String?;
      if (token == null) return;

      final groupId = controller.currentGroupId.value;
      final filename = 'group_${groupId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final presignRes = await http.post(
        Uri.parse('https://api.43-202-101-63.sslip.io/uploads/presign'
            '?filename=$filename&contentType=image%2Fjpeg&acl=public-read'),
        headers: {'accept': 'application/json', 'Authorization': 'Bearer $token'},
      );

      print('presign: ${presignRes.statusCode}');
      String? publicUrl;

      if (presignRes.statusCode == 200) {
        final body = jsonDecode(presignRes.body) as Map<String, dynamic>;
        final String uploadUrl = body['url']?.toString() ?? '';
        final rawFields = body['fields'] as Map? ?? {};
        final Map<String, String> fields = {};
        rawFields.forEach((k, v) => fields[k.toString()] = v.toString());

        if (uploadUrl.isNotEmpty && fields.isNotEmpty) {
          final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
          fields.forEach((k, v) => request.fields[k] = v);
          request.files.add(await http.MultipartFile.fromPath('file', picked.path, filename: filename));
          final s3Res = await request.send();
          if (s3Res.statusCode == 200 || s3Res.statusCode == 204) {
            publicUrl = body['publicUrl']?.toString() ?? '$uploadUrl${fields['key'] ?? filename}';
          }
        }
        publicUrl ??= body['publicUrl']?.toString();
      }

      final finalUrl = (publicUrl != null && publicUrl.isNotEmpty) ? publicUrl : picked.path;
      controller.groupBackgroundImage.value = finalUrl;
      GetStorage().write('group_img_$groupId', finalUrl);

      // 내 그룹 목록 갱신 (GetStorage 폴백 반영)
      if (Get.isRegistered<MyGroupController>()) {
        Get.find<MyGroupController>().fetchMyGroups();
      }

      Get.snackbar("완료", "프로필 사진이 변경되었습니다.");
    } catch (e) {
      print('프로필 사진 변경 오류: $e');
      Get.snackbar("오류", "사진 변경에 실패했습니다.");
    }
  }
}
