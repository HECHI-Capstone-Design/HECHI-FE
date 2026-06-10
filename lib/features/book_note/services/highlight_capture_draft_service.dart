import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/highlight_capture_draft.dart';

class HighlightCaptureDraftService {
  HighlightCaptureDraftService._();

  static final HighlightCaptureDraftService instance =
      HighlightCaptureDraftService._();

  static const String _storageKey = 'highlight_capture_drafts';
  final GetStorage _box = GetStorage();

  Future<List<HighlightCaptureDraft>> getDraftsForBook(int bookId) async {
    final drafts = await getAllDrafts();
    return drafts.where((draft) => draft.bookId == bookId).toList()
      ..sort((a, b) {
        if (a.page != b.page) return a.page.compareTo(b.page);
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  Future<int> countDraftsForBook(int bookId) async {
    final drafts = await getDraftsForBook(bookId);
    return drafts.length;
  }

  Future<List<HighlightCaptureDraft>> getAllDrafts() async {
    final rawList = _box.read<List<dynamic>>(_storageKey) ?? <dynamic>[];
    final drafts = rawList
        .whereType<Map>()
        .map(
          (item) =>
              HighlightCaptureDraft.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((draft) => draft.id.isNotEmpty)
        .toList();

    final validDrafts = <HighlightCaptureDraft>[];
    bool changed = false;

    for (final draft in drafts) {
      if (await File(draft.imagePath).exists()) {
        validDrafts.add(draft);
      } else {
        changed = true;
      }
    }

    if (changed) {
      await _writeDrafts(validDrafts);
    }

    return validDrafts;
  }

  Future<HighlightCaptureDraft> saveCapture({
    required int bookId,
    required String bookTitle,
    required int page,
    required String sourcePath,
  }) async {
    final sourceFile = File(sourcePath);
    final extension = sourceFile.path.contains('.')
        ? sourceFile.path.split('.').last
        : 'jpg';

    return saveCaptureBytes(
      bookId: bookId,
      bookTitle: bookTitle,
      page: page,
      bytes: await sourceFile.readAsBytes(),
      fileExtension: extension,
    );
  }

  Future<HighlightCaptureDraft> saveCaptureBytes({
    required int bookId,
    required String bookTitle,
    required int page,
    required List<int> bytes,
    String fileExtension = 'jpg',
  }) async {
    final targetPath = await _createTargetPath(fileExtension);
    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(bytes, flush: true);

    final draft = HighlightCaptureDraft(
      id: _extractDraftId(targetPath),
      bookId: bookId,
      bookTitle: bookTitle,
      page: page,
      imagePath: targetPath,
      createdAt: DateTime.now().toIso8601String(),
    );

    final drafts = await getAllDrafts();
    drafts.add(draft);
    await _writeDrafts(drafts);

    return draft;
  }

  Future<void> deleteDraft(String id) async {
    final drafts = await getAllDrafts();
    final matchIndex = drafts.indexWhere((draft) => draft.id == id);
    if (matchIndex == -1) return;

    final draft = drafts.removeAt(matchIndex);
    final file = File(draft.imagePath);
    if (await file.exists()) {
      await file.delete();
    }

    await _writeDrafts(drafts);
  }

  Future<Directory> _ensureDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory('${dir.path}/highlight_capture_drafts');
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target;
  }

  Future<void> _writeDrafts(List<HighlightCaptureDraft> drafts) async {
    await _box.write(
      _storageKey,
      drafts.map((draft) => draft.toJson()).toList(),
    );
  }

  Future<String> _createTargetPath(String extension) async {
    final directory = await _ensureDirectory();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    return '${directory.path}/$id.$extension';
  }

  String _extractDraftId(String path) {
    final fileName = path.split('/').last;
    final dotIndex = fileName.lastIndexOf('.');
    return dotIndex == -1 ? fileName : fileName.substring(0, dotIndex);
  }
}
