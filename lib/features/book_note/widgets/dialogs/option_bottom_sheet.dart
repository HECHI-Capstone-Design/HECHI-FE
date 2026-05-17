import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/book_note_controller.dart';
import '../overlays/creation_overlay.dart';

class OptionBottomSheet extends StatelessWidget {
  final String type; // bookmark | highlight | memo
  final Map<String, dynamic> data;

  const OptionBottomSheet({
    super.key,
    required this.type,
    required this.data,
  });

  bool get hasMemo {
    final memo = data["memo"];
    return memo != null && memo.toString().trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookNoteController>();

    return _SelectBottomSheet(
      title: type == "bookmark" ? "북마크"
          : type == "highlight" ? "하이라이트"
          : "메모",
      items: [
        "삭제",
        type == "memo" ? "메모 수정" : (hasMemo ? "메모 수정" : "메모 작성"),
        "그룹 공유",
      ],
      itemColors: [
        Colors.red.withValues(alpha: 0.7),
        Colors.black87,
        Colors.black87,
      ],
      onSelect: (index) {
        Get.back();
        if (index == 0) {
          if (type == "bookmark")
            controller.deleteBookmark(data["id"]);
          else if (type == "highlight")
            controller.deleteHighlight(data["id"]);
          else
            controller.deleteMemo(data["id"]);
        } else if (index == 1) {
          _openEditor();
        } else {
          _openGroupSelectSheet();
        }
      },
    );
  }

  // -------------------------------------------------------------
  // 그룹 선택 바텀시트
  // -------------------------------------------------------------
  void _openGroupSelectSheet() {
    // TODO: Replace dummy data with API response
    // GET /groups/my → 내가 포함된 그룹 목록
    final dummyGroups = [
      {"id": "1", "name": "그룹 1"},
      {"id": "2", "name": "그룹 2"},
    ];

    Get.bottomSheet(
      _SelectBottomSheet(
        title: "그룹 선택",
        items: dummyGroups.map((g) => g["name"]!).toList(),
        onSelect: (index) {
          final selectedGroup = dummyGroups[index];
          Get.back();
          _openBoardSelectSheet(selectedGroup["id"]!, selectedGroup["name"]!);
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // 게시판 선택 바텀시트
  // -------------------------------------------------------------
  void _openBoardSelectSheet(String groupId, String groupName) {
    // TODO: Replace dummy data with API response
    // GET /groups/{groupId}/boards → 해당 그룹의 게시판 목록
    final dummyBoards = {
      "1": [
        {"id": "1", "name": "게시판 1"},
        {"id": "2", "name": "게시판 2"},
      ],
      "2": [
        {"id": "3", "name": "게시판 1"},
        {"id": "4", "name": "게시판 2"},
      ],
    };

    final boards = dummyBoards[groupId] ?? [];

    Get.bottomSheet(
      _SelectBottomSheet(
        title: "게시판 선택",
        items: boards.map((b) => b["name"]!).toList(),
        onSelect: (index) {
          final selectedBoard = boards[index];
          Get.back();
          // TODO: POST /groups/{groupId}/boards/{boardId}/posts
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // CreationOverlay 호출 (작성/수정 공통 처리)
  // -------------------------------------------------------------
  void _openEditor() {
    if (type == "bookmark") {
      Get.bottomSheet(
        CreationOverlay(
          type: "bookmark",
          isEdit: true,
          itemId: data["id"],
          page: data["page"],
          memo: hasMemo ? data["memo"] : "",
        ),
        isScrollControlled: true,
      );
      return;
    }

    if (type == "highlight") {
      Get.bottomSheet(
        CreationOverlay(
          type: "highlight",
          isEdit: true,
          itemId: data["id"],
          page: data['page'],
          sentence: data["sentence"],
          memo: hasMemo ? data["memo"] : "",
          isPublic: data["is_public"] ?? false,
        ),
        isScrollControlled: true,
      );
      return;
    }

    Get.bottomSheet(
      CreationOverlay(
        type: "memo",
        isEdit: true,
        itemId: data["id"],
        content: data["content"],
      ),
      isScrollControlled: true,
    );
  }
}

// -------------------------------------------------------------
// 공통 선택 바텀시트
// -------------------------------------------------------------
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
            // ── 헤더
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
                      color: Color(0xFF3F3F3F),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Text(
                      "취소",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF4DB56C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),

            // ── 아이템 목록
            ...items.asMap().entries.map((entry) => InkWell(
              onTap: () => onSelect(entry.key),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 0.5, color: Color(0xFFDADADA)),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: itemColors?[entry.key] ?? const Color(0xFF3F3F3F),
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
