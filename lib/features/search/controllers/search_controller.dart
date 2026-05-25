// lib/features/search/controllers/search_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // 💡 토큰을 꺼내오기 위한 임포트
import '../data/book_model.dart';
import '../data/search_repository.dart';
import '../pages/isbn_scan_view.dart';
import 'package:hechi/features/myGroup/models/group_model.dart';

enum SearchState { initial, emptyHistory, hasHistory, result }

class BookSearchController extends GetxController {
  // HTTP 통신을 위한 GetConnect 인스턴스 및 Base URL 정의
  final GetConnect _connect = GetConnect();
  static const String baseUrl = 'https://api.43-202-101-63.sslip.io';
  
  // 로컬 스토리지에 저장된 access_token을 읽기 위한 스토리지 선언
  final GetStorage _storage = GetStorage();

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

  // 💡 현재 선택된 검색 카테고리 탭 인덱스 상태 관리 (0: 책, 1: 컬렉션, 2: 그룹)
  final RxInt selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    searchFocusNode.addListener(_onFocusChange);
    searchTextController.addListener(() {
      isTextEmpty.value = searchTextController.text.isEmpty;
    });
    loadServerHistory();
  }

  // 사용자가 상단 카테고리 탭을 변경했을 때 호출되는 함수
  void changeTab(int index) {
    selectedTabIndex.value = index;
    print("🎯 현재 검색 카테고리 변경됨: 탭 인덱스 $index");
    
    if (currentView.value == SearchState.result && currentKeyword.value.isNotEmpty) {
      if (index == 0) {
        refreshSearch(); 
      } else if (index == 1) {
        // TODO: 컬렉션 검색 API 연동 필요 시 호출
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
    if (value.isEmpty) return;
    recentSearches.removeWhere((item) => item.query == value);
    final tempItem = SearchHistoryItem(id: -1, query: value);
    recentSearches.insert(0, tempItem);

    currentKeyword.value = value;
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
      await searchGroups(value);
      
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

  @override
  void onClose() {
    searchTextController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }
}