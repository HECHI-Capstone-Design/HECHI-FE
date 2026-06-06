import 'package:hechi/app/colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import '../../controllers/book_note_controller.dart';
import '../../../groupcommunity/controllers/group_controller.dart';
import '../../../groupcommunity/pages/group_post_create_view.dart';

mixin GroupShareMixin {
  static const String _baseUrl = "https://api.43-202-101-63.sslip.io";

  String get _token => GetStorage().read('access_token') ?? "";
  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer $_token",
  };

  void openGroupShareFlow({
    required String itemType,
    required Map<String, dynamic> itemData,
    required int bookId,
  }) {
    _openGroupSelectSheet(itemType: itemType, itemData: itemData, bookId: bookId);
  }

  Future<void> _openGroupSelectSheet({
    required String itemType,
    required Map<String, dynamic> itemData,
    required int bookId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/me/groups'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        _showErrorSnackbar();
        return;
      }

      final dynamic raw = jsonDecode(utf8.decode(response.bodyBytes));
      final List groups = raw['groups'] ?? [];

      if (groups.isEmpty) {
        Get.snackbar(
          "그룹 없음",
          "가입된 그룹이 없습니다.",
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
        );
        return;
      }

      Get.bottomSheet(
        _SelectBottomSheet(
          title: "그룹 선택",
          items: groups.map((g) => g["name"]?.toString() ?? "").toList(),
          onSelect: (index) {
            final selectedGroup = groups[index];
            final String groupId = selectedGroup["groupId"]?.toString() ?? "";
            Get.back();
            _fetchAndOpenBoardSelectSheet(
              groupId: groupId,
              itemType: itemType,
              itemData: itemData,
              bookId: bookId,
            );
          },
        ),
      );
    } catch (e) {
      print("❌ Fetch Groups Error: $e");
      _showErrorSnackbar();
    }
  }

  Future<void> _fetchAndOpenBoardSelectSheet({
    required String groupId,
    required String itemType,
    required Map<String, dynamic> itemData,
    required int bookId,
  }) async {
    try {
      final boardsRes = await http.get(
        Uri.parse('$_baseUrl/groups/$groupId/boards'),
        headers: _headers,
      );
      final groupRes = await http.get(
        Uri.parse('$_baseUrl/groups/$groupId'),
        headers: _headers,
      );

      if (boardsRes.statusCode != 200) {
        _showErrorSnackbar();
        return;
      }

      final List boards = jsonDecode(utf8.decode(boardsRes.bodyBytes))['boards'] ?? [];

      int? missionBookId;
      if (groupRes.statusCode == 200) {
        final groupData = jsonDecode(utf8.decode(groupRes.bodyBytes));
        missionBookId = int.tryParse(
            groupData["currentMissionBook"]?["bookId"]?.toString() ?? ""
        );
      }

      _openBoardSelectSheet(
        groupId: groupId,
        boards: boards,
        itemType: itemType,
        itemData: itemData,
        bookId: bookId,
        missionBookId: missionBookId,
      );
    } catch (e) {
      print("❌ Fetch Boards Error: $e");
      _showErrorSnackbar();
    }
  }

  void _openBoardSelectSheet({
    required String groupId,
    required List boards,
    required String itemType,
    required Map<String, dynamic> itemData,
    required int bookId,
    required int? missionBookId,
  }) {
    if (boards.isEmpty) {
      Get.snackbar(
        "게시판 없음",
        "게시판이 없습니다.",
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    Get.bottomSheet(
      _SelectBottomSheet(
        title: "게시판 선택",
        items: boards.map((b) => b["label"]?.toString() ?? "").toList(),
        onSelect: (index) {
          final selectedBoard = boards[index];
          final String boardType = selectedBoard["boardType"]?.toString() ?? "";
          Get.back();
          _shareToBoard(
            groupId: groupId,
            boardType: boardType,
            boardData: Map<String, dynamic>.from(selectedBoard),
            itemType: itemType,
            itemData: itemData,
            bookId: bookId,
            missionBookId: missionBookId,
          );
        },
      ),
    );
  }

  void _shareToBoard({
    required String groupId,
    required String boardType,
    required Map<String, dynamic> boardData,
    required String itemType,
    required Map<String, dynamic> itemData,
    required int bookId,
    required int? missionBookId,
  }) {
    final bool isMission = boardType == "MISSION";

    if (isMission && missionBookId != null && missionBookId != bookId) {
      Get.snackbar(
        "미션책이 아닙니다",
        "현재 그룹의 미션책의 독서기록만 미션게시판에 공유할 수 있습니다.",
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    Get.delete<GroupController>();
    final groupCtrl = Get.put(GroupController());
    groupCtrl.currentGroupId.value = groupId;
    groupCtrl.attachNote(itemType, itemData);

    if (!isMission && bookId != 0) {
      final bookNoteCtrl = Get.find<BookNoteController>();
      final bookInfo = bookNoteCtrl.bookInfo;
      groupCtrl.attachedBookId.value = bookId;
      groupCtrl.attachedBookTitle.value = bookInfo["title"]?.toString() ?? "";
      final authors = bookInfo["authors"] as List?;
      groupCtrl.attachedBookAuthor.value =
          (authors != null && authors.isNotEmpty) ? authors.first.toString() : "";
      groupCtrl.attachedBookCover.value = bookInfo["thumbnail"]?.toString() ?? "";
      groupCtrl.isBookAttached.value = true;
    }

    groupCtrl.fetchAllDataFromAPI();
    Get.to(() => GroupPostCreateView(isMission: isMission));
  }

  void _showErrorSnackbar() {
    Get.snackbar(
      "오류",
      "잠시 후 다시 시도해주세요.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade400,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }
}

class _SelectBottomSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final void Function(int index) onSelect;
  final List<Color>? itemColors;

  const _SelectBottomSheet({
    required this.title,
    required this.items,
    required this.onSelect,
    this.itemColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text(
                      "취소",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: AppColors.border),
            ...items.asMap().entries.map((entry) => InkWell(
              onTap: () => onSelect(entry.key),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 0.5, color: AppColors.border),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: itemColors?[entry.key] ?? AppColors.textDark,
                  ),
                ),
              ),
            )),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}