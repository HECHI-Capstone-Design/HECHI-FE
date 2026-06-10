import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_ocr_flutter/mobile_ocr_flutter.dart';

import '../controllers/book_note_controller.dart';
import '../data/models/highlight_capture_draft.dart';
import '../services/highlight_capture_draft_service.dart';
import '../widgets/overlays/creation_overlay.dart';
import '../widgets/overlays/ocr_line_selection_overlay.dart';

class HighlightCaptureReviewPage extends StatefulWidget {
  const HighlightCaptureReviewPage({super.key});

  @override
  State<HighlightCaptureReviewPage> createState() =>
      _HighlightCaptureReviewPageState();
}

class _HighlightCaptureReviewPageState extends State<HighlightCaptureReviewPage> {
  final HighlightCaptureDraftService _draftService =
      HighlightCaptureDraftService.instance;

  late final BookNoteController _controller;
  bool _isLoading = true;
  String? _processingDraftId;
  List<HighlightCaptureDraft> _drafts = const [];

  @override
  void initState() {
    super.initState();
    _controller = Get.find<BookNoteController>();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final drafts = await _draftService.getDraftsForBook(_controller.bookId);
    if (!mounted) return;
    setState(() {
      _drafts = drafts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedDrafts = _groupDraftsByPage(_drafts);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "저장된 촬영본",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : groupedDrafts.isEmpty
              ? const Center(
                  child: Text(
                    "저장된 촬영본이 없습니다.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDrafts,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                    itemCount: groupedDrafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final entry = groupedDrafts[index];
                      return _PageDraftSection(
                        page: entry.key,
                        drafts: entry.value,
                        processingDraftId: _processingDraftId,
                        onSelectDraft: _reviewDraft,
                        onDeleteDraft: _deleteDraft,
                      );
                    },
                  ),
                ),
    );
  }

  List<MapEntry<int, List<HighlightCaptureDraft>>> _groupDraftsByPage(
    List<HighlightCaptureDraft> drafts,
  ) {
    final grouped = <int, List<HighlightCaptureDraft>>{};
    for (final draft in drafts) {
      grouped.putIfAbsent(draft.page, () => <HighlightCaptureDraft>[]).add(draft);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in entries) {
      entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return entries;
  }

  Future<void> _reviewDraft(HighlightCaptureDraft draft) async {
    if (_processingDraftId != null) return;

    setState(() {
      _processingDraftId = draft.id;
    });

    try {
      final result = await MobileOcr.recognizeFilePath(draft.imagePath);
      final candidateLines = result.lines
          .map((line) => line.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      if (candidateLines.isEmpty) {
        Get.snackbar("안내", "추출된 문장이 없습니다.");
        return;
      }

      final selectedText = await Get.bottomSheet<String>(
        OcrLineSelectionOverlay(lines: candidateLines),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );

      if (selectedText == null || selectedText.trim().isEmpty) {
        return;
      }

      await Get.bottomSheet(
        CreationOverlay(
          type: "highlight",
          isEdit: false,
          page: draft.page,
          sentence: selectedText.trim(),
          onCreateSuccess: () async {
            await _draftService.deleteDraft(draft.id);
            await _loadDrafts();
          },
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    } catch (_) {
      Get.snackbar("오류", "저장된 이미지에서 문장 추출에 실패했습니다.");
    } finally {
      if (mounted) {
        setState(() {
          _processingDraftId = null;
        });
      }
    }
  }

  Future<void> _deleteDraft(HighlightCaptureDraft draft) async {
    await _draftService.deleteDraft(draft.id);
    await _loadDrafts();
  }
}

class _PageDraftSection extends StatelessWidget {
  const _PageDraftSection({
    required this.page,
    required this.drafts,
    required this.processingDraftId,
    required this.onSelectDraft,
    required this.onDeleteDraft,
  });

  final int page;
  final List<HighlightCaptureDraft> drafts;
  final String? processingDraftId;
  final Future<void> Function(HighlightCaptureDraft draft) onSelectDraft;
  final Future<void> Function(HighlightCaptureDraft draft) onDeleteDraft;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "p. $page",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${drafts.length}개의 촬영본",
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888888),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: drafts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final isProcessing = processingDraftId == draft.id;
              return SizedBox(
                width: 120,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InkWell(
                        onTap: isProcessing ? null : () => onSelectDraft(draft),
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE8E8E8)),
                            image: DecorationImage(
                              image: FileImage(File(draft.imagePath)),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: isProcessing
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: InkWell(
                        onTap: () => onDeleteDraft(draft),
                        borderRadius: BorderRadius.circular(999),
                        child: Ink(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
