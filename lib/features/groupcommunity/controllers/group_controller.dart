import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:hechi/features/search/data/search_repository.dart';
import 'package:hechi/features/search/data/book_model.dart'; 

class GroupController extends GetxController {
  // 🌐 백엔드 API 호스트 Base URL
  final String baseUrl = "https://api.43-202-101-63.sslip.io";

  // 🔔 테스트 데이터 고정 연동: 그룹 ID '111' 지정 완비
  final currentGroupId = "111".obs; 
  final isLeader = true.obs; 
  final isLoading = false.obs;

  final SearchRepository _searchRepository = SearchRepository();

  // 🔑 [인증 레이어]: GetStorage access_token 헤더 규격화
  String get _token => GetStorage().read('access_token') ?? "";
  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer $_token",
  };

  // --- 실시간 백엔드 매핑 상태 변수 ---
  final groupName = "".obs;
  final currentMissionBookId = 0.obs; 
  final currentMissionBookTitle = "".obs;
  final currentMissionBookAuthor = "".obs;
  final currentMissionBookCover = "".obs;
  
  final groupAverageProgress = 0.0.obs;
  final myProgress = 0.0.obs;

  // 🔔 [과거 도서 마스터 캐시 뱅크]: 서버에서 내려준 그룹 소속 도서 풀셋 저장고
  final Map<int, Map<String, String>> groupBookCacheMaster = <int, Map<String, String>>{};

  // --- 반응형 데이터 스트림 수집 보관함 ---
  final memberList = <Map<String, dynamic>>[].obs;
  final missionPosts = <Map<String, dynamic>>[].obs; 
  final freePosts = <Map<String, dynamic>>[].obs;     
  final announcements = <Map<String, dynamic>>[].obs;
  final reportList = <Map<String, dynamic>>[].obs;
  final missionHistory = <Map<String, dynamic>>[].obs; 

  final historyMissionPosts = <Map<String, dynamic>>[].obs;
  final historySelectedBookTitle = "".obs;
  final historySelectedBookCover = "".obs;
  final historySelectedBookAuthor = "".obs;

  final searchedBooksResult = <Book>[].obs;
  final isSearching = false.obs;

  final isBookAttached = false.obs;
  final attachedBookId = 0.obs; 
  final attachedBookTitle = "".obs;
  final attachedBookAuthor = "".obs;
  final attachedBookCover = "".obs;

  final isDiscussionAttached = false.obs;
  final discussionTopic = "".obs;
  final discussionOptions = <String>[].obs;
  final discussionEndTimeString = "종료시간 미설정".obs;

  @override
  void onInit() {
    super.onInit();
    fetchAllDataFromAPI();
  }

  // ------------------------------------------------------------------
  // 🌐 GET: 백엔드 API 통합 데이터 패치 엔진
  // ------------------------------------------------------------------
  Future<void> fetchAllDataFromAPI() async {
    try {
      isLoading.value = true;
      final gId = currentGroupId.value;

      print("\n================ [🚀 RAW 대조 정품 동기화 정밀 매핑 기동] ================\n");

      final groupRes = await http.get(Uri.parse('$baseUrl/groups/$gId'), headers: _headers);
      
      if (groupRes.statusCode == 200) {
        final Map<String, dynamic> groupData = jsonDecode(utf8.decode(groupRes.bodyBytes));
        groupName.value = groupData["name"] ?? "hechi1";
        
        final currentBookObj = groupData["currentMissionBook"];
        if (currentBookObj != null) {
          currentMissionBookId.value = int.tryParse(currentBookObj["bookId"]?.toString() ?? "0") ?? 0;
          currentMissionBookTitle.value = currentBookObj["title"]?.toString() ?? "미설정";
          currentMissionBookCover.value = currentBookObj["thumbnail"] ?? "";
          
          final List? authorsList = currentBookObj["authors"];
          currentMissionBookAuthor.value = (authorsList != null && authorsList.isNotEmpty) 
              ? authorsList.first.toString() 
              : "저자 정보 없음";
          
          groupBookCacheMaster[currentMissionBookId.value] = {
            "title": currentMissionBookTitle.value,
            "author": currentMissionBookAuthor.value,
            "cover": currentMissionBookCover.value,
          };

          final double rawGroupProgress = double.tryParse(currentBookObj["groupAverageProgressPercent"]?.toString() ?? "0.0") ?? 0.0;
          final double rawMyProgress = double.tryParse(currentBookObj["myProgressPercent"]?.toString() ?? "0.0") ?? 0.0;
          groupAverageProgress.value = rawGroupProgress > 1.0 ? rawGroupProgress / 100.0 : rawGroupProgress;
          myProgress.value = rawMyProgress > 1.0 ? rawMyProgress / 100.0 : rawMyProgress;
        }

        final List? allMissionBooks = groupData["missionBooks"];
        if (allMissionBooks != null) {
          for (var b in allMissionBooks) {
            final int bId = int.tryParse(b["bookId"]?.toString() ?? "0") ?? 0;
            if (bId != 0) {
              final List? authList = b["authors"];
              groupBookCacheMaster[bId] = {
                "title": b["title"]?.toString() ?? "제목 없음",
                "author": (authList != null && authList.isNotEmpty) ? authList.first.toString() : "저자 미상",
                "cover": b["thumbnail"]?.toString() ?? "",
              };
            }
          }
        }

        final List dynamicMembers = groupData["members"] ?? [];
        memberList.value = dynamicMembers.map((m) => {
          "id": m["memberId"]?.toString() ?? "0",
          "nickname": m["nickname"] ?? "그룹원",
          "progress": double.tryParse(m["missionProgressPercent"]?.toString() ?? "0.0") ?? 0.0
        }).toList();
      }

      // 2) [GET] /groups/{groupId}/mission-books/history
      final historyRes = await http.get(Uri.parse('$baseUrl/groups/$gId/mission-books/history'), headers: _headers).catchError((_)=>http.Response('[]',404));
      if (historyRes.statusCode == 200) {
        final dynamic rawData = jsonDecode(utf8.decode(historyRes.bodyBytes));
        List listData = (rawData is List) ? rawData : (rawData['items'] ?? []);
        
        final Set<String> seenBookIds = <String>{};
        final List<Map<String, dynamic>> distinctHistory = [];

        for (var item in listData) {
          final String bId = item["bookId"]?.toString() ?? item["id"]?.toString() ?? "";
          if (bId.isNotEmpty && !seenBookIds.contains(bId)) {
            seenBookIds.add(bId);
            
            final List? authList = item["authors"];
            final String itemAuthor = (authList != null && authList.isNotEmpty) ? authList.first.toString() : "저자 미상";
            
            distinctHistory.add({
              "bookId": bId,
              "title": item["title"] ?? "제목 없음",
              "author": itemAuthor,
              "cover": item["thumbnail"] ?? item["cover"] ?? "", 
              "changedAt": item["month"] ?? item["createdAt"] ?? "이전 기록",
            });

            final int intBId = int.tryParse(bId) ?? 0;
            if (intBId != 0 && !groupBookCacheMaster.containsKey(intBId)) {
              groupBookCacheMaster[intBId] = {
                "title": item["title"] ?? "제목 없음",
                "author": itemAuthor,
                "cover": item["thumbnail"] ?? item["cover"] ?? "",
              };
            }
          }
        }
        missionHistory.value = distinctHistory;
      }

      // 3) [GET] /groups/{groupId}/posts?type=MISSION
      final missionPostRes = await http.get(Uri.parse('$baseUrl/groups/$gId/posts?type=MISSION'), headers: _headers).catchError((_)=>http.Response('[]',404));
      if (missionPostRes.statusCode == 200) {
        final dynamic rawM = jsonDecode(utf8.decode(missionPostRes.bodyBytes));
        List mData = (rawM is Map) ? (rawM['posts'] ?? []) : (rawM is List ? rawM : []);
        missionPosts.value = mData.map((item) => _parsePostItem(item)).toList();
      }

      // 4) [GET] /groups/{groupId}/posts?type=FREE
      final freePostRes = await http.get(Uri.parse('$baseUrl/groups/$gId/posts?type=FREE'), headers: _headers).catchError((_)=>http.Response('[]',404));
      if (freePostRes.statusCode == 200) {
        final dynamic rawF = jsonDecode(utf8.decode(freePostRes.bodyBytes));
        List fData = (rawF is Map) ? (rawF['posts'] ?? []) : (rawF is List ? rawF : []);
        freePosts.value = fData.map((item) => _parsePostItem(item)).toList();
      }

      final annRes = await http.get(Uri.parse('$baseUrl/groups/$gId/announcements'), headers: _headers).catchError((_)=>http.Response('[]',404));
      if (annRes.statusCode == 200) {
        final dynamic rawAnn = jsonDecode(utf8.decode(annRes.bodyBytes));
        List annData = (rawAnn is List) ? rawAnn : (rawAnn['items'] ?? []);
        announcements.value = annData.map((item) => {
          "id": item["postId"]?.toString() ?? item["id"]?.toString() ?? "0", 
          "title": item["title"] ?? "공지사항",
          "content": item["content"] ?? "",
          "isPinned": (item["isPinned"] ?? false as bool).obs,
        }).toList();
      }

      print("================ [🚀 명세 대조 멸균 완료] ================\n");
    } catch (e) {
      print("🚨 최종 동기화 세션 오류: $e");
    } finally { // 🔔 [완치 장치]: 문법 오류를 일으킨 오타 구문을 안전하게 바꿨습니다.
      isLoading.value = false;
    }
  }

  // ------------------------------------------------------------------
  // 🌐 GET: 책별 고유 게시판 분리 필터 조회 기능
  // ------------------------------------------------------------------
  Future<void> fetchFilteredBookBoard(String bookId, bool isMission) async {
    try {
      isLoading.value = true;
      final String typeParam = isMission ? "MISSION" : "FREE";
      final url = Uri.parse('$baseUrl/groups/${currentGroupId.value}/posts?type=$typeParam&bookId=$bookId');
      
      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final dynamic rawData = jsonDecode(utf8.decode(response.bodyBytes));
        List postData = (rawData is Map) ? (rawData['posts'] ?? []) : (rawData is List ? rawData : []);
        
        if (isMission) {
          missionPosts.value = postData.map((item) => _parsePostItem(item)).toList();
        } else {
          freePosts.value = postData.map((item) => _parsePostItem(item)).toList();
        }
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  // --- 과거 미션북 및 검색 인터페이스 엔진 ---
  Future<void> fetchHistoryBookBoard(Map<String, dynamic> historyBook) async { try { isLoading.value = true; historySelectedBookTitle.value = historyBook["title"] ?? ""; historySelectedBookAuthor.value = historyBook["author"] ?? ""; historySelectedBookCover.value = historyBook["cover"] ?? ""; final String bId = historyBook["bookId"]?.toString() ?? "0"; final response = await http.get(Uri.parse('$baseUrl/groups/${currentGroupId.value}/posts?type=MISSION&bookId=$bId'), headers: _headers); if (response.statusCode == 200) { final dynamic rawPosts = jsonDecode(utf8.decode(response.bodyBytes)); List postData = (rawPosts is Map) ? (rawPosts['posts'] ?? []) : (rawPosts is List ? rawPosts : []); historyMissionPosts.value = postData.map((item) => _parsePostItem(item)).toList(); } } catch (_) {} finally { isLoading.value = false; } }
  Future<void> searchBooksFromAPI(String query) async { if (query.trim().isEmpty) { searchedBooksResult.clear(); return; } try { isSearching.value = true; final List<Book> books = await _searchRepository.searchBooks(query); searchedBooksResult.value = List.from(books); } catch (_) {} finally { isSearching.value = false; } }
  Future<bool> changeMissionBook(String isbn) async { try { final response = await http.patch(Uri.parse('$baseUrl/groups/${currentGroupId.value}/mission-book'), headers: _headers, body: jsonEncode({"isbn": isbn})); if (response.statusCode == 200 || response.statusCode == 204) { await fetchAllDataFromAPI(); return true; } return false; } catch (_) { return false; } }
  
  // ------------------------------------------------------------------
  // 🌐 POST: 게시글 작성
  // ------------------------------------------------------------------
  Future<void> createNewPost(String title, String content, bool isMission) async {
    try {
      final url = Uri.parse('$baseUrl/groups/${currentGroupId.value}/posts');
      final int? finalBookId = isMission 
          ? (currentMissionBookId.value != 0 ? currentMissionBookId.value : null)
          : (attachedBookId.value != 0 ? attachedBookId.value : null);

      final Map<String, dynamic> bodyData = {
        "type": isMission ? "MISSION" : "FREE",
        "title": title,
        "content": content,
        "bookId": finalBookId,
        "recordId": null,
      };

      if (isDiscussionAttached.value && discussionTopic.value.trim().isNotEmpty) {
        bodyData["discussion"] = {
          "question": discussionTopic.value,
          "options": List<String>.from(discussionOptions)
        };
      } else {
        bodyData.remove("discussion");
      }
      
      final response = await http.post(url, headers: _headers, body: jsonEncode(bodyData));
      if (response.statusCode == 200 || response.statusCode == 201) await fetchAllDataFromAPI();
    } catch (_) {
    } finally { 
      removeAttachedBook();
      removeAttachedDiscussion();
    }
  }

  // ------------------------------------------------------------------
  // 🌐 POST: 🔔 댓글 작성 정품 인터페이스 (이탈 구문 완전 수리)
  // ------------------------------------------------------------------
  Future<bool> addCommentToPost(dynamic postArg, String content) async {
    if (content.trim().isEmpty) return false;
    try {
      String postId = "0";
      if (postArg is Map) { postId = postArg["id"]?.toString() ?? "0"; } else { postId = postArg.toString(); }
      final url = Uri.parse('$baseUrl/groups/posts/$postId/comments');
      final response = await http.post(url, headers: _headers, body: jsonEncode({"content": content}));
      if (response.statusCode == 200 || response.statusCode == 201) { await fetchAllDataFromAPI(); return true; }
      return false;
    } catch (_) { return false; }
  }

  // ------------------------------------------------------------------
  // 🌐 POST: 🔔 답글 작성 정품 인터페이스 (완전 복구 완료)
  // ------------------------------------------------------------------
  Future<bool> addReplyToComment(dynamic commentArg, String content) async {
    if (content.trim().isEmpty) return false;
    try {
      String commentId = "0";
      if (commentArg is Map) { commentId = commentArg["id"]?.toString() ?? "0"; } else { commentId = commentArg.toString(); }
      final url = Uri.parse('$baseUrl/groups/comments/$commentId/replies');
      final response = await http.post(url, headers: _headers, body: jsonEncode({"content": content}));
      if (response.statusCode == 200 || response.statusCode == 201) { await fetchAllDataFromAPI(); return true; }
      return false;
    } catch (_) { return false; }
  }
  
  // ------------------------------------------------------------------
  // 🌐 🔔 [메인 연동 누락 메서드 전면 구조 복구 완료]
  // ------------------------------------------------------------------
  Future<void> castVote(Map<String, dynamic> post, int optionIndex) async { 
    try { 
      await http.post(Uri.parse('$baseUrl/groups/posts/${post["id"]}/discussion/vote'), headers: _headers, body: jsonEncode({"optionId": optionIndex})); 
      await fetchAllDataFromAPI(); 
    } catch (_) {} 
  }

  Future<void> addAnnouncement(String title, String content) async { 
    try { 
      final response = await http.post(Uri.parse('$baseUrl/groups/${currentGroupId.value}/announcements'), headers: _headers, body: jsonEncode({"title": title, "content": content})); 
      if (response.statusCode == 200 || response.statusCode == 201) await fetchAllDataFromAPI(); 
    } catch (_) {} 
  }

  Future<void> togglePostLike(Map<String, dynamic> post) async { 
    final bool current = post["isLiked"].value; 
    post["isLiked"].value = !current; 
    if (post["isLiked"].value) { post["likes"].value++; } else { post["likes"].value--; } 
    try { 
      final url = Uri.parse('$baseUrl/groups/posts/${post["id"]}/like'); 
      if (current) { await http.delete(url, headers: _headers); } else { await http.post(url, headers: _headers); } 
    } catch (_) {} 
  }

  Future<void> addReport(String reason, Map<String, dynamic> targetPost) async { 
    try { 
      await http.post(Uri.parse('$baseUrl/groups/posts/${targetPost["id"]}/report'), headers: _headers, body: jsonEncode({"reason": reason})); 
    } catch (_) {} 
  }

  Future<void> toggleCommentLike(Map<String, dynamic> comment) async { 
    final bool current = comment["isCommentLiked"].value; 
    comment["isCommentLiked"].value = !current; 
    if (comment["isCommentLiked"].value) { comment["likes"].value++; } else { comment["likes"].value--; } 
    try { 
      final url = Uri.parse('$baseUrl/groups/comments/${comment["id"]}/like'); 
      if (current) { await http.delete(url, headers: _headers); } else { await http.post(url, headers: _headers); } 
    } catch (_) {} 
  }

  Future<void> togglePinAnnouncement(Map<String, dynamic> announcement) async { 
    if (announcement["id"] == null) return; 
    try { 
      await http.patch(Uri.parse('$baseUrl/groups/posts/${announcement["id"]}/pin'), headers: _headers); 
      await fetchAllDataFromAPI(); 
    } catch (_) {} 
  }

  void deleteAnnouncement(Map<String, dynamic> announcement) async { 
    try { 
      await http.delete(Uri.parse('$baseUrl/groups/posts/${announcement["id"]}'), headers: _headers); 
      await fetchAllDataFromAPI(); 
    } catch (_) {} 
  }

  Future<void> kickMember(String nickname) async { 
    final target = memberList.firstWhere((m) => m["nickname"] == nickname, orElse: () => {}); 
    if (target.isNotEmpty) { 
      try { 
        await http.delete(Uri.parse('$baseUrl/groups/${currentGroupId.value}/members/${target["id"]}'), headers: _headers); 
        await fetchAllDataFromAPI(); 
      } catch (_) {} 
    } 
  }

  void attachBook(dynamic bookObj, String title, String author, String cover) {
    if (bookObj is Book) { attachedBookId.value = int.tryParse(bookObj.id?.toString() ?? "1") ?? 1; }
    else if (bookObj is Map) { attachedBookId.value = int.tryParse(bookObj["id"]?.toString() ?? "1") ?? 1; }
    else { attachedBookId.value = int.tryParse(bookObj?.toString() ?? "1") ?? 1; }
    attachedBookTitle.value = title; attachedBookAuthor.value = author; attachedBookCover.value = cover; isBookAttached.value = true;
    if (attachedBookId.value != 0) {
      groupBookCacheMaster[attachedBookId.value] = {"title": title, "author": author, "cover": cover};
    }
  }
  
  void removeAttachedBook() { attachedBookId.value = 0; attachedBookTitle.value = ""; attachedBookAuthor.value = ""; attachedBookCover.value = ""; isBookAttached.value = false; }
  void attachDiscussion(String topic, List<String> options, String endTime) { discussionTopic.value = topic; discussionOptions.assignAll(options); discussionEndTimeString.value = endTime; isDiscussionAttached.value = true; }
  void removeAttachedDiscussion() { discussionTopic.value = ""; discussionOptions.clear(); discussionEndTimeString.value = "종료시간 미설정"; isDiscussionAttached.value = false; }

  // ------------------------------------------------------------------
  // 🌐 GET: 캐시 뱅크 기반 멸균 파싱 엔진
  // ------------------------------------------------------------------
  Map<String, dynamic> _parsePostItem(dynamic item) {
    if (item == null) return {};
    final String postType = item["type"]?.toString() ?? "";
    final bool isMissionPost = (postType == "MISSION" || postType == "mission");
    
    final int baseLikes = int.tryParse((item["likeCount"] ?? item["likesCount"] ?? 0).toString()) ?? 0;
    final bool baseIsLiked = item["isLiked"] ?? false;
    final int parsedBookId = int.tryParse(item["bookId"]?.toString() ?? "0") ?? 0;

    String finalTitle = "";
    String finalAuthor = "";
    String finalCover = "";

    if (parsedBookId != 0 && groupBookCacheMaster.containsKey(parsedBookId)) {
      finalTitle = groupBookCacheMaster[parsedBookId]?["title"] ?? "";
      finalAuthor = groupBookCacheMaster[parsedBookId]?["author"] ?? "";
      finalCover = groupBookCacheMaster[parsedBookId]?["cover"] ?? "";
    } else {
      finalTitle = item["bookTitle"]?.toString() ?? (attachedBookId.value == parsedBookId ? attachedBookTitle.value : "첨부 도서");
      finalAuthor = item["bookAuthor"]?.toString() ?? (attachedBookId.value == parsedBookId ? attachedBookAuthor.value : "");
      finalCover = item["bookCover"]?.toString() ?? (attachedBookId.value == parsedBookId ? attachedBookCover.value : "");
    }

    final List rawComments = item["comments"] ?? [];
    final List<Map<String, dynamic>> parsedComments = rawComments.map((c) {
      return {"id": c["commentId"]?.toString() ?? c["id"]?.toString() ?? "0", "author": c["authorName"] ?? c["author"] ?? "익명", "content": c["content"] ?? "", "likes": int.tryParse((c["likeCount"] ?? 0).toString()) ?? 0, "isCommentLiked": c["isLiked"] ?? false};
    }).toList();

    final dynamic discussionObj = item["discussion"];
    final bool serverHasPoll = discussionObj != null && discussionObj is Map && discussionObj.isNotEmpty && discussionObj.containsKey("question") && discussionObj["question"].toString().trim().isNotEmpty;

    return {
      "id": item["postId"]?.toString() ?? item["id"]?.toString() ?? "0",
      "author": item["authorName"] ?? item["author"] ?? "알 수 없음",
      "date": item["createdAt"] ?? item["date"] ?? "방금 전",
      "content": item["content"] ?? "",
      "isMission": isMissionPost,
      "bookId": parsedBookId, 
      "bookTitle": parsedBookId == 0 ? "" : finalTitle,
      "bookAuthor": parsedBookId == 0 ? "" : finalAuthor,
      "bookCover": parsedBookId == 0 ? "" : finalCover,
      "likes": baseLikes.obs, "isLiked": baseIsLiked.obs, "hasPoll": serverHasPoll, "pollQuestion": serverHasPoll ? discussionObj["question"]?.toString() ?? "" : "", "pollOptions": serverHasPoll && discussionObj["options"] != null ? List<String>.from(discussionObj["options"]) : <String>[], "pollVotes": <int>[].obs, "selectedOption": (-1).obs, "comments": parsedComments.obs,
    };
  }
}