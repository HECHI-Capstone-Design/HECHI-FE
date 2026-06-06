import 'package:hechi/app/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/features/groupcommunity/controllers/group_controller.dart';
import 'package:hechi/features/search/data/book_model.dart';
import 'package:hechi/features/book_note/widgets/bookmark_item.dart';
import 'package:hechi/features/book_note/widgets/highlight_item.dart';
import 'package:hechi/features/book_note/widgets/memo_item.dart';
import 'package:hechi/features/book_note/controllers/book_note_controller.dart';

class GroupPostCreateView extends StatefulWidget {
  final bool isMission;
  const GroupPostCreateView({Key? key, required this.isMission}) : super(key: key);

  @override
  State<GroupPostCreateView> createState() => _GroupPostCreateViewState();
}

class _GroupPostCreateViewState extends State<GroupPostCreateView> {
  late final TextEditingController _contentController;
  late final GroupController _controller;
  static const brandColor = AppColors.primaryLight;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController();
    _controller = Get.find<GroupController>();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Get.back()),
        title: Text(widget.isMission ? "[미션게시판] 글쓰기" : "[자유게시판] 글쓰기",
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              final bool hasContent = _contentController.text.isNotEmpty;
              final bool hasNotes = _controller.attachedNotes.isNotEmpty;
              if (hasContent || hasNotes) {
                _controller.createNewPost('', _contentController.text, widget.isMission);
                Get.back();
              } else {
                Get.snackbar("내용을 입력해주세요", "",
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(16),
                    borderRadius: 8);
              }
            },
            child: const Text("확인", style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  controller: _contentController, maxLines: null, minLines: 8, cursorColor: brandColor,
                  decoration: const InputDecoration(hintText: "책과 함께 내 생각을 기록해보세요..!", border: InputBorder.none),
                ),
                const SizedBox(height: 16),

                if (!widget.isMission)
                  Obx(() => _controller.isBookAttached.value
                      ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.textDark, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Container(width: 45, height: 65,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4),
                              image: DecorationImage(image: NetworkImage(_controller.attachedBookCover.value), fit: BoxFit.cover))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_controller.attachedBookTitle.value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text(_controller.attachedBookAuthor.value, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ])),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => _controller.removeAttachedBook())
                    ]),
                  )
                      : const SizedBox.shrink()),

                Obx(() => _controller.isDiscussionAttached.value
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.poll_outlined, color: brandColor, size: 18),
                          const SizedBox(width: 6),
                          Expanded(child: Text("토론 주제: ${_controller.discussionTopic.value}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                          IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                              onPressed: () => _controller.removeAttachedDiscussion())
                        ]),
                        const Divider(),
                        ..._controller.discussionOptions.map((opt) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text("• $opt", style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        )).toList(),
                      ],
                    ),
                  ),
                )
                    : const SizedBox.shrink()),

                Obx(() {
                  if (_controller.attachedNotes.isEmpty) return const SizedBox.shrink();
                  return Column(
                    children: _controller.attachedNotes.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final String type = entry.value["type"];
                      final Map<String, dynamic> data = Map<String, dynamic>.from(entry.value["data"]);
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Stack(
                          children: [
                            switch (type) {
                              "bookmark"  => BookmarkItem(data: data, isReadOnly: true, isPreview: true),
                              "highlight" => HighlightItem(data: data, isReadOnly: true, isPreview: true),
                              "memo"      => MemoItem(data: data, isReadOnly: true, isPreview: true),
                              _           => const SizedBox.shrink(),
                            },
                            Positioned(
                              top: 0, right: 0,
                              child: GestureDetector(
                                onTap: () => _controller.removeAttachedNote(index: index),
                                child: const Icon(Icons.close, size: 18, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }),
              ]),
            ),
          ),

          SafeArea(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), offset: const Offset(0, -3), blurRadius: 4)],
                  border: const Border(top: BorderSide(color: AppColors.backgroundGrey))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!widget.isMission) _buildOptionRow(Icons.search, "도서 추가", _showBookSearchPage),
                  _buildOptionRow(Icons.edit_note, "독서기록", _showBookNoteSelector),
                  _buildOptionRow(Icons.poll_outlined, "토론", _showDiscussionPage),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
        child: Row(children: [
          Icon(icon, color: Colors.black87, size: 20), const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14)), const Spacer(),
          const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey)
        ]),
      ),
    );
  }

  void _showBookNoteSelector() {
    final int bookId = widget.isMission
        ? _controller.currentMissionBookId.value
        : _controller.attachedBookId.value;

    if (bookId == 0) {
      Get.snackbar("도서를 먼저 추가해주세요", "독서기록을 공유하려면 도서를 먼저 선택해주세요.",
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16), borderRadius: 8);
      return;
    }

    Get.toNamed('/book_note', arguments: {
      'bookId': bookId,
      'tabIndex': 0,
      'preselectedGroupId': _controller.currentGroupId.value,
      'preselectedBoardId': null,
    })?.then((_) {
      if (Get.isRegistered<BookNoteController>()) {
        Get.find<BookNoteController>().onItemSelected = null;
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (Get.isRegistered<BookNoteController>()) {
        Get.find<BookNoteController>().onItemSelected = (itemType, itemData) {
          _controller.attachNote(itemType, itemData);
        };
      }
    });
  }

  void _showBookSearchPage() {
    Get.to(() => const _BookSearchPage());
  }

  void _showDiscussionPage() {
    Get.to(() => const _DiscussionPage());
  }
}

// 도서 검색 페이지 (별도 StatefulWidget으로 TextEditingController 안전 관리)
class _BookSearchPage extends StatefulWidget {
  const _BookSearchPage();
  @override
  State<_BookSearchPage> createState() => _BookSearchPageState();
}

class _BookSearchPageState extends State<_BookSearchPage> {
  late final TextEditingController _searchController;
  late final GroupController _controller;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _controller = Get.find<GroupController>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, title: const Text("도서 추가"), centerTitle: true),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onSubmitted: (val) => _controller.searchBooksFromAPI(val),
            decoration: InputDecoration(
                hintText: "책 제목 검색", prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.grey.shade100, border: InputBorder.none),
          ),
        ),
        Expanded(child: Obx(() {
          if (_controller.isSearching.value) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: _controller.searchedBooksResult.length,
            itemBuilder: (context, index) {
              final Book book = _controller.searchedBooksResult[index];
              final String coverUrl = book.thumbnail ?? "https://images.unsplash.com/photo-1495640388908-05fa85288e61?q=80&w=200";
              return ListTile(
                leading: Container(
                  width: 40, height: 60,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                  child: Image.network(coverUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                ),
                title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(book.authorString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                onTap: () { _controller.attachBook(book, book.title, book.authorString, coverUrl); Get.back(); },
              );
            },
          );
        }))
      ]),
    );
  }
}

// 토론 설정 페이지 (별도 StatefulWidget으로 TextEditingController 안전 관리)
class _DiscussionPage extends StatefulWidget {
  const _DiscussionPage();
  @override
  State<_DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<_DiscussionPage> {
  late final TextEditingController _topicController;
  late final RxList<TextEditingController> _itemFields;
  late final GroupController _controller;
  static const brandColor = AppColors.primaryLight;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController();
    _itemFields = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
    ].obs;
    _controller = Get.find<GroupController>();
  }

  @override
  void dispose() {
    _topicController.dispose();
    for (final c in _itemFields) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Get.back()),
        title: const Text("토론 투표 설정", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              final List<String> options = _itemFields.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
              if (_topicController.text.isNotEmpty && options.length >= 2) {
                _controller.attachDiscussion(_topicController.text, options, "종료시간 생략");
                Get.back();
              } else {
                Get.snackbar("알림", "주제와 최소 2개 이상의 투표 항목을 입력하세요.");
              }
            },
            child: const Text("완료", style: TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _topicController, cursorColor: brandColor,
                decoration: const InputDecoration(hintText: "토론 투표 주제를 입력하세요...", border: UnderlineInputBorder()),
              ),
              const SizedBox(height: 24),
              const Text("투표 선택 항목", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() => ListView.builder(
                  itemCount: _itemFields.length,
                  itemBuilder: (context, idx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                              child: TextField(
                                controller: _itemFields[idx], cursorColor: brandColor,
                                decoration: InputDecoration(hintText: "${idx + 1}번 항목 입력", border: InputBorder.none),
                              ),
                            ),
                          ),
                          if (_itemFields.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () {
                                _itemFields[idx].dispose();
                                _itemFields.removeAt(idx);
                              },
                            )
                        ],
                      ),
                    );
                  },
                )),
              ),
              Obx(() {
                if (_itemFields.length >= 6) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: InkWell(
                    onTap: () => _itemFields.add(TextEditingController()),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: brandColor)),
                      child: const Center(child: Text("+ 다른 선택 항목 추가", style: TextStyle(color: brandColor, fontWeight: FontWeight.bold))),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
