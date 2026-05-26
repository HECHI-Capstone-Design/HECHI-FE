// lib/features/search/controllers/search_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart'; // 💡 토큰을 꺼내오기 위한 임포트
import '../data/book_model.dart';
import '../data/search_repository.dart';
import '../pages/isbn_scan_view.dart';
import 'package:hechi/features/myGroup/models/group_model.dart';
import '../../collection/models/collection_list_model.dart';

enum SearchState { initial, emptyHistory, hasHistory, result }

class BookSearchController extends GetxController {
  // HTTP 통신을 위한 GetConnect 인스턴스 및 Base URL 정의
  final GetConnect _connect = GetConnect();
  static const String baseUrl = 'https://api.43-202-101-63.sslip.io';
  
  // 로컬 스토리지에 저장된 access_token을 읽기 위한 스토리지 선언
  final box = GetStorage();

  String? get _token => box.read('access_token');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  final Rx<SearchState> currentView = SearchState.initial.obs;
  final TextEditingController searchTextController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final RxBool isTextEmpty = true.obs;
  final RxList<SearchHistoryItem> recentSearches = <SearchHistoryItem>[].obs;
  final RxString currentKeyword = ''.obs;
  final SearchRepository _repository = SearchRepository();
  
  // 📚 책 관련 상태 변수
  final RxList<Book> searchResults = <Book>[].obs;
  final RxBool isLoading = false.obs;
  final RxSet<int> registeredBookIds = <int>{}.obs;

  // 👥 그룹 검색 관련 상태 변수
  final RxList<GroupModel> groupSearchResults = <GroupModel>[].obs;
  final RxBool isGroupLoading = false.obs;

  // ── 컬렉션 검색 관련 상태 변수
  final RxList<CollectionListItem> collectionSearchResults = <CollectionListItem>[].obs;
  final RxBool isCollectionLoading = false.obs;

  // ── 태그 드롭다운 관련
  final RxBool isTagDropdownVisible = false.obs;
  final RxList<Map<String, dynamic>> tagDropdownResults = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> tagCategories = <Map<String, dynamic>>[].obs;
  final RxString selectedTagCategory = ''.obs;
  final RxList<Map<String, dynamic>> currentCategoryTags = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> selectedSearchTags = <Map<String, dynamic>>[].obs;

  // 💡 현재 선택된 검색 카테고리 탭 인덱스 상태 관리 (0: 책, 1: 컬렉션, 2: 그룹)
  final RxInt selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    searchFocusNode.addListener(_onFocusChange);
    searchTextController.addListener(() {
      isTextEmpty.value = searchTextController.text.isEmpty;
      _onSearchTextChanged(searchTextController.text);
    });
    loadServerHistory();
    _fetchTagCategories();
  }

  void _onSearchTextChanged(String text) async {
    final trimmed = text.trim();
    if (trimmed.startsWith('#')) {
      isTagDropdownVisible.value = true;
      final query = text.substring(1);
      if (query.isEmpty) {
        // # 만 입력 시 카테고리 목록 표시
        tagDropdownResults.clear();
        selectedTagCategory.value = '';
        currentCategoryTags.clear();
        return;
      }
      // 태그 검색
      selectedTagCategory.value = '';
      currentCategoryTags.clear();
      try {
        final uri = Uri.parse('$baseUrl/tags').replace(queryParameters: {
          'query': query,
          'limit': '30',
        });
        final res = await http.get(uri, headers: _headers);
        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          tagDropdownResults.assignAll(
              List<Map<String, dynamic>>.from(data['tags'] ?? [])
          );
        }
      } catch (e) {
        print('❌ tag search error: $e');
      }
    } else {
      isTagDropdownVisible.value = false;
      tagDropdownResults.clear();
      selectedTagCategory.value = '';
      currentCategoryTags.clear();
    }
  }

  // 사용자가 상단 카테고리 탭을 변경했을 때 호출되는 함수
  void changeTab(int index) {
    selectedTabIndex.value = index;
    print("🎯 현재 검색 카테고리 변경됨: 탭 인덱스 $index");
    
    if (currentView.value == SearchState.result && currentKeyword.value.isNotEmpty) {
      if (index == 0) {
        refreshSearch(); 
      } else if (index == 1) {
        searchCollectionsWithFilter();
      } else if (index == 2) {
        searchGroups(currentKeyword.value); 
      }
    }
  }

  Future<void> loadServerHistory() async {
    final history = await _repository.getSearchHistory();
    recentSearches.assignAll(history);
    if (recentSearches.isEmpty && currentView.value == SearchState.hasHistory) {
      currentView.value = SearchState.emptyHistory;
    }
  }

  void _onFocusChange() {
    if (searchFocusNode.hasFocus && currentView.value != SearchState.result) {
      _checkHistoryState();
    }
  }

  void _checkHistoryState() {
    if (recentSearches.isNotEmpty) {
      currentView.value = SearchState.hasHistory;
    } else {
      currentView.value = SearchState.emptyHistory;
    }
  }

  void navigateToIsbnScan() => Get.to(() => const IsbnScanView());

  void clearSearchText() {
    searchTextController.clear();
    if (currentView.value == SearchState.result) {
      backToSearch();
    } else {
      _checkHistoryState();
    }
  }

  /// 🌐 사용자가 키워드를 치고 검색(엔터)했을 때 호출되는 핵심 함수
  Future<void> onSubmit(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty && selectedSearchTags.isEmpty) return;
    isTagDropdownVisible.value = false;

    if (trimmed.startsWith('#')) {
      final tagName = trimmed.substring(1).trim();
      if (tagName.isEmpty) return;
      searchFocusNode.unfocus();
      currentView.value = SearchState.result;
      selectedTabIndex.value = 1;
      await searchCollectionsByRawTagName(tagName);
      return;
    }

    if (selectedSearchTags.isNotEmpty && trimmed.isEmpty) {
      currentKeyword.value = selectedSearchTags.map((t) => '#${t['name']}').join(' ');
      searchFocusNode.unfocus();
      currentView.value = SearchState.result;
      selectedTabIndex.value = 1;
      await searchCollectionsWithFilter();
      return;
    }

    recentSearches.removeWhere((item) => item.query == trimmed);
    final tempItem = SearchHistoryItem(id: -1, query: trimmed);
    recentSearches.insert(0, tempItem);

    currentKeyword.value = trimmed;
    searchFocusNode.unfocus();
    currentView.value = SearchState.result;

    isLoading.value = true;
    searchResults.clear();

    try {
      // 1. 기본값인 '책' 검색 API 수행
      final books = await _repository.searchBooks(value);
      searchResults.assignAll(books);
      await _syncReadingStatus(books);
      await loadServerHistory();
      
      // 2. 그룹 검색 API도 백그라운드에서 한 번에 같이 호출
      await searchGroups(trimmed);
      await searchCollectionsWithFilter();
      
    } catch (e) {
      print("에러 발생: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// 🌐 👥 실제 API 연동: 그룹 검색 (GET /groups/search) -> 💡 403 인증 토큰 및 모델 바인딩 정밀 조율
  Future<void> searchGroups(String query) async {
    if (query.trim().isEmpty) return;

    try {
      isGroupLoading.value = true;
      groupSearchResults.clear();

      // 스토리지에서 내 로그인 토큰을 동적으로 꺼내옵니다.
      final storage = GetStorage();
      final String? token = storage.read('access_token');
      
      final headers = {
        'accept': 'application/json',
        // 토큰이 유효하다면 Authorization 헤더를 명시적으로 장착!
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // 명세서 기반: 쿼리 파라미터로 ?query=검색어 추가
      final response = await _connect.get(
        '$baseUrl/groups/search?query=${Uri.encodeComponent(query)}',
        headers: headers,
      );

      if (response.statusCode == 200 && response.body != null) {
        final List<dynamic>? groupList = response.body['groups'];
        if (groupList != null) {
          final parsedGroups = groupList.map((json) {
            // 💡 [수정] UI 카드 디자인에 방장 닉네임이 출력되어야 하므로 가상 매핑 가드를 세워줍니다.
            // 만약 백엔드 응답 데이터 구조에 특정 필드가 부족하더라도 UI가 깨지거나 터지지 않도록 방어합니다.
            return GroupModel(
              id: json['groupId']?.toString() ?? '',
              title: json['name'] ?? '이름 없는 그룹',
              description: json['description'] ?? '설명이 없습니다.',
              // 카드 내부 상단에 '달해', 'summer' 등의 닉네임을 유연하게 표현할 수 있도록authorName 바인딩 최적화
              authorName: (json['ownerNickname'] != null && json['ownerNickname'].toString().isNotEmpty)
                  ? json['ownerNickname'].toString()
                  : 'summer', 
            );
          }).toList();

          groupSearchResults.assignAll(parsedGroups);
          print('✅ 그룹 검색 연동 성공: 총 ${groupSearchResults.length}개 발견 및 동적 매핑 완료');
        }
      } else {
        print('❌ 그룹 검색 API 에러: ${response.statusText} (${response.statusCode})');
      }
    } catch (e) {
      print('❌ 그룹 검색 중 통신 예외 발생: $e');
    } finally {
      isGroupLoading.value = false;
    }
  }

  /// 전체 새로고침 시 책과 그룹 데이터를 모두 리프레시합니다.
  Future<void> refreshSearch() async {
    if (currentKeyword.value.isNotEmpty) {
      print("🔄 검색 결과 새로고침 중...");
      final books = await _repository.searchBooks(currentKeyword.value);
      searchResults.assignAll(books);
      await _syncReadingStatus(books);
      
      await searchGroups(currentKeyword.value);
      await searchCollections(currentKeyword.value);
    }
  }

  Future<void> _syncReadingStatus(List<Book> books) async {
    final List<int> myReadingIds = await _repository.getMyReadingBookIds();
    final Set<int> newRegisteredIds = {};

    for (var book in books) {
      if (myReadingIds.contains(book.id)) {
        newRegisteredIds.add(book.id);
      }
    }

    registeredBookIds.assignAll(newRegisteredIds);
    print("🔄 UI 동기화 완료: 체크된 도서 ${registeredBookIds.length}권");
  }

  Future<void> clearAllHistory() async {
    final success = await _repository.deleteAllHistory();
    if (success) {
      recentSearches.clear();
      currentView.value = SearchState.emptyHistory;
    }
  }

  Future<void> deleteOneHistory(int historyId) async {
    final success = await _repository.deleteHistoryItem(historyId);
    if (success) {
      recentSearches.removeWhere((item) => item.id == historyId);
      if (recentSearches.isEmpty) {
        currentView.value = SearchState.emptyHistory;
      }
    } else {
      Get.snackbar("알림", "삭제에 실패했습니다.");
    }
  }

  void backToSearch() {
    searchTextController.clear();
    searchResults.clear();
    groupSearchResults.clear();
    collectionSearchResults.clear();
    selectedSearchTags.clear();
    currentView.value = SearchState.initial;
    loadServerHistory();
  }

  void showRegisterDialog(Book book) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '\'${book.title}\'를 등록하시겠습니까?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3F3F3F)),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '해당 도서는 도서 보관함 \'읽는 중\'에 포함되고,\n북스토퍼에 등록됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF888888), height: 1.4),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        bool success = await _repository.registerReadingBook(book.id);
                        if (success) {
                          registeredBookIds.add(book.id);
                          Get.back();
                          Get.snackbar(
                            "알림",
                            "'${book.title}' 도서가 등록되었습니다.",
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.black87,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(20),
                          );
                        } else {
                          Get.snackbar("오류", "도서 등록에 실패했습니다. 다시 시도해 주세요.", snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16)),
                      child: const Center(child: Text('예', style: TextStyle(fontSize: 16, color: Color(0xFF4CAF50), fontWeight: FontWeight.w500))),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFEEEEEE)),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Get.back();
                        print("📖 '${book.title}' 상세 페이지로 이동");
                        await Get.toNamed('/book_detail_page', arguments: book.id);
                        refreshSearch();
                      },
                      borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
                      child: const Center(child: Text('도서 상세', style: TextStyle(fontSize: 16, color: Color(0xFF4CAF50), fontWeight: FontWeight.w500))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 컬렉션 검색 메서드 추가
  Future<void> _fetchTagCategories() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/tags/categories'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        tagCategories.assignAll(
          List<Map<String, dynamic>>.from(data['categories'] ?? []),
        );
      }
    } catch (e) {
      print('❌ _fetchTagCategories error: $e');
    }
  }

  Future<void> selectTagCategory(Map<String, dynamic> category) async {
    selectedTagCategory.value = category['name'] ?? '';
    try {
      final uri = Uri.parse('$baseUrl/tags').replace(queryParameters: {
        'category': category['name'],
        'limit': '100',
      });
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        currentCategoryTags.assignAll(
          List<Map<String, dynamic>>.from(data['tags'] ?? []),
        );
      }
    } catch (e) {
      print('❌ selectTagCategory error: $e');
    }
  }

  void clearTagCategory() {
    selectedTagCategory.value = '';
    currentCategoryTags.clear();
  }

  Future<void> searchCollectionsWithFilter() async {
    try {
      isCollectionLoading.value = true;
      collectionSearchResults.clear();

      final String queryText = searchTextController.text.trim();
      final String finalQuery = queryText.startsWith('#') ? '' : queryText;

      final Map<String, String> queryParams = {
        'sort': 'like',
        'limit': '50',
      };

      if (finalQuery.isNotEmpty) {
        queryParams['query'] = finalQuery;
      }

      if (selectedSearchTags.isNotEmpty) {
        final tagIdsStr = selectedSearchTags.map((t) => t['tagId'].toString()).join(',');
        queryParams['tagIds'] = tagIdsStr;
      }

      if (queryParams['query'] == null && queryParams['tagIds'] == null) {
        return;
      }

      final uri = Uri.parse('$baseUrl/collections').replace(queryParameters: queryParams);
      print("📡 공개 컬렉션 필터 질의 URL: $uri");

      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (data['collections'] as List)
            .map((e) => CollectionListItem.fromJson(e))
            .toList();
        collectionSearchResults.assignAll(list);
      }
    } catch (e) {
      print('❌ searchCollectionsWithFilter 예외 발생: $e');
    } finally {
      isCollectionLoading.value = false;
    }
  }

  Future<void> searchCollectionsByRawTagName(String tagName) async {
    try {
      isCollectionLoading.value = true;
      collectionSearchResults.clear();

      final tagUri = Uri.parse('$baseUrl/tags').replace(queryParameters: {'query': tagName, 'limit': '1'});
      final tagRes = await http.get(tagUri, headers: _headers);
      if (tagRes.statusCode == 200) {
        final tagData = jsonDecode(utf8.decode(tagRes.bodyBytes));
        final List tagsList = tagData['tags'] ?? [];
        if (tagsList.isNotEmpty) {
          final targetTag = tagsList.first;
          selectedSearchTags.add(targetTag);
          searchTextController.text = '';
          isTextEmpty.value = true;
          currentKeyword.value = selectedSearchTags.map((t) => '#${t['name']}').join(' '); // ★ 추가
          await searchCollectionsWithFilter();
          return;
        }
      }
    } catch (e) {
      print('❌ searchCollectionsByRawTagName error: $e');
    } finally {
      isCollectionLoading.value = false;
    }
  }

  void selectTag(Map<String, dynamic> tag) {
    if (!selectedSearchTags.any((t) => t['tagId'] == tag['tagId'])) {
      selectedSearchTags.add(tag);
    }
    searchTextController.text = '';
    isTextEmpty.value = true;
    isTagDropdownVisible.value = false;
    tagDropdownResults.clear();
    selectedTagCategory.value = '';
    currentCategoryTags.clear();
    currentKeyword.value = selectedSearchTags.map((t) => '#${t['name']}').join(' ');
    searchFocusNode.unfocus();
    currentView.value = SearchState.result;
    selectedTabIndex.value = 1;
    searchCollectionsWithFilter();
  }

  void removeSearchTag(Map<String, dynamic> tag) {
    selectedSearchTags.removeWhere((t) => t['tagId'] == tag['tagId']);
    if (selectedSearchTags.isEmpty) {
      searchTextController.clear();
      backToSearch();
    } else {
      currentKeyword.value = selectedSearchTags.map((t) => '#${t['name']}').join(' ');
      searchCollectionsWithFilter();
    }
  }

  Future<void> _searchCollectionsByTagIds(List<String> tagIds) async {
    try {
      isCollectionLoading.value = true;
      collectionSearchResults.clear();
      final uri = Uri.parse(
          '$baseUrl/collections?tagIds=${tagIds.join(",")}&sort=like&limit=50'
      );
      final res = await http.get(uri, headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (data['collections'] as List)
            .map((e) => CollectionListItem.fromJson(e))
            .toList();
        collectionSearchResults.assignAll(list);
      }
    } catch (e) {
      print('❌ _searchCollectionsByTagIds error: $e');
    } finally {
      isCollectionLoading.value = false;
    }
  }

  Future<void> searchCollections(String query) async {
    if (query.trim().isEmpty || query.startsWith('#')) return;
    try {
      isCollectionLoading.value = true;
      collectionSearchResults.clear();

      final uri = Uri.parse('$baseUrl/collections').replace(queryParameters: {
        'query': query,
        'sort': 'like',
        'limit': '50',
      });

      final res = await http.get(uri, headers: _headers);

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final list = (data['collections'] as List)
            .map((e) => CollectionListItem.fromJson(e))
            .toList();
        collectionSearchResults.assignAll(list);
        print('✅ 컬렉션 검색 성공: ${list.length}개');
      } else {
        print('❌ 컬렉션 검색 실패: ${res.statusCode}');
      }
    } catch (e) {
      print('❌ searchCollections error: $e');
    } finally {
      isCollectionLoading.value = false;
    }
  }

// ── 컬렉션 좋아요 토글
  void toggleCollectionLike(String collectionId) async {
    final index = collectionSearchResults.indexWhere((c) => c.id == collectionId);
    if (index == -1) return;

    final item = collectionSearchResults[index];
    final isCurrentlyLiked = item.isLiked;
    collectionSearchResults[index] = item.copyWith(isLiked: !isCurrentlyLiked);

    try {
      final res = isCurrentlyLiked
          ? await http.delete(
        Uri.parse('$baseUrl/collections/$collectionId/like'),
        headers: _headers,
      )
          : await http.post(
        Uri.parse('$baseUrl/collections/$collectionId/like'),
        headers: _headers,
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        collectionSearchResults[index] = CollectionListItem(
          id: collectionSearchResults[index].id,
          title: collectionSearchResults[index].title,
          description: collectionSearchResults[index].description,
          authorName: collectionSearchResults[index].authorName,
          tags: collectionSearchResults[index].tags,
          bookCoverUrls: collectionSearchResults[index].bookCoverUrls,
          likeCount: data['likeCount'],
          bookCount: collectionSearchResults[index].bookCount,
          isLiked: data['isLiked'],
          isPublic: collectionSearchResults[index].isPublic,
        );
      } else {
        collectionSearchResults[index] = item;
      }
    } catch (e) {
      collectionSearchResults[index] = item;
      print('❌ toggleCollectionLike error: $e');
    }
  }

  @override
  void onClose() {
    searchTextController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }
}