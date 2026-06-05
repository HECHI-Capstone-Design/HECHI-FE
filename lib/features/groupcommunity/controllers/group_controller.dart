import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:hechi/features/search/data/search_repository.dart';
import 'package:hechi/features/search/data/book_model.dart';
import '../../myGroup/models/group_model.dart';

class GroupController extends GetxController {
  final String baseUrl = "https://api.43-202-101-63.sslip.io";

  final currentGroupId = "".obs;
  final isLeader = false.obs;
  final isLoading = false.obs;

  final SearchRepository _searchRepository = SearchRepository();

  String get _token => GetStorage().read('access_token') ?? "";
  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "Authorization": "Bearer $_token",
  };

  final groupName = "".obs;
  final currentMissionBookId = 0.obs;
  final currentMissionBookTitle = "".obs;
  final currentMissionBookAuthor = "".obs;
  final currentMissionBookCover = "".obs;

  final groupAverageProgress = 0.0.obs;
  final myProgress = 0.0.obs;

  final Map<int, Map<String, String>> groupBookCacheMaster = <int, Map<String, String>>{};

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

  final attachedNotes = <Map<String, dynamic>>[].obs;
  bool get isNoteAttached => attachedNotes.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      if (Get.arguments is String) {
        currentGroupId.value = Get.arguments as String;
      } else if (Get.arguments is GroupModel) {
        currentGroupId.value = (Get.arguments as GroupModel).id;
      }
      print("🚀 [컨트롤러 기동] 아규먼트로 수신한 진짜 방 ID: ${currentGroupId.value}");
    }

    if (currentGroupId.value.isEmpty) {
      print("🛡️ [안전 가드] 진입한 방 ID가 비어있어 API 요청을 차단합니다.");
      return;
    }
    fetchAllDataFromAPI();
  }

  Future<void> fetchAllDataFromAPI() async {
    try {
      isLoading.value = true;
      final gId = currentGroupId.value;

      final groupRes = await http.get(Uri.parse('$baseUrl/groups/$gId'), headers: _headers);

      if (groupRes.statusCode == 200) {
        final Map<String, dynamic> groupData = jsonDecode(utf8.decode(groupRes.bodyBytes));
        groupName.value = groupData["name"] ?? "hechi1";

        isLeader.value = groupData["isLeader"] ?? false;

        final currentBookObj = groupData["currentMissionBook"];
        if (currentBookObj != null) {
          final rawBookId = currentBookObj["id"] ?? currentBookObj["bookId"];
          currentMissionBookId.value = int.tryParse(rawBookId?.toString() ?? "0") ?? 0;
          
          currentMissionBookTitle.value = currentBookObj["title"]?.toString() ?? "미설정";
          currentMissionBookCover.value = currentBookObj["thumbnail"] ?? "";

          print("📚 [고유 ID 확보 완결] 서버 맵핑 결과 추출한 책 ID: ${currentMissionBookId.value}");

          final List? authorsList = currentBookObj["authors"];
          currentMissionBookAuthor.value = (authorsList != null && authorsList.isNotEmpty)
              ? authorsList.first.toString()
              : "저자 정보 없음";

          if (currentMissionBookId.value != 0) {
            groupBookCacheMaster[currentMissionBookId.value] = {
              "title": currentMissionBookTitle.value,
              "author": currentMissionBookAuthor.value,
              "cover": currentMissionBookCover.value,
            };
          }

          final double rawGroupProgress = double.tryParse(currentBookObj["groupAverageProgressPercent"]?.toString() ?? "0.0") ?? 0.0;
          final double rawMyProgress = double.tryParse(currentBookObj["myProgressPercent"]?.toString() ?? "0.0") ?? 0.0;
          groupAverageProgress.value = rawGroupProgress > 1.0 ? rawGroupProgress / 100.0 : rawGroupProgress;
          myProgress.value = rawMyProgress > 1.0 ? rawMyProgress / 100.0 : rawMyProgress;
        }

        final List? allMissionBooks = groupData["missionBooks"];
        if (allMissionBooks != null) {
          for (var b in allMissionBooks) {
            final int bId = int.tryParse((b["id"] ?? b["bookId"])?.toString() ?? "0") ?? 0;
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

      final historyRes = await http.get(Uri.parse('$baseUrl/groups/$gId/mission-books/history'), headers: _headers).catchError((_)=>http.Response('[]',404));
      if (historyRes.statusCode == 200) {
        final dynamic rawData = jsonDecode(utf8.decode(historyRes.bodyBytes));
        List listData = (rawData is List) ? rawData : (rawData['items'] ?? []);

        final Set<String> seenBookIds = <String>{};
        final List<Map<String, dynamic>> distinctHistory = [];

        for (var item in listData) {
          final String bId = item["id"]?.toString() ?? item["bookId"]?.toString() ?? "";
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

      await refreshPostsOnly();

      final annRes = await http.get(Uri.parse('$baseUrl/groups/${currentGroupId.value}/announcements'), headers: _headers).catchError((_)=>http.Response('[]',404));
      if (annRes.statusCode == 200) {
        final dynamic rawAnn = jsonDecode(utf8.decode(annRes.bodyBytes));
        print("🔍 [공지사항 RAW 바디 디버깅]: $rawAnn");

        List annData = [];
        if (rawAnn is List) {
          annData = rawAnn;
        } else if (rawAnn is Map) {
          annData = rawAnn['posts'] ?? rawAnn['items'] ?? rawAnn['announcements'] ?? [];
        }
        announcements.value = annData.map((item) => {
          "id": item["postId"]?.toString() ?? item["id"]?.toString() ?? "0",
          "title": item["title"] ?? "공지사항",
          "content": item["content"] ?? "",
          "isPinned": (item["isPinned"] ?? false).toString().toLowerCase() == 'true' ? true.obs : false.obs,
        }).toList();
        announcements.sort((a, b) {
          final bool aPinned = a["isPinned"].value;
          final bool bPinned = b["isPinned"].value;
          if (aPinned && !bPinned) return -1;
          if (!aPinned && bPinned) return 1;
          return 0;
        });
        announcements.refresh();

        print("📢 [공지사항 파싱 및 상단 고정 정렬 완료]");
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> parseCommentsList(dynamic rawComments) {
    final List comments = (rawComments is List) ? rawComments : [];
    return comments.map((c) {
      final List rawReplies = c["replies"] ?? [];
      final List<Map<String, dynamic>> parsedReplies = rawReplies.map((r) {
        return {
          "id": (r["commentId"] ?? "0").toString(),
          "author": r["userName"] ?? "익명",
          "content": r["content"] ?? "",
          "likes": (int.tryParse((r["likeCount"] ?? 0).toString()) ?? 0).obs,
          "isCommentLiked": ((r["isLiked"] ?? false) as bool).obs,
        };
      }).toList();

      return {
        "id": (c["commentId"] ?? "0").toString(),
        "author": c["userName"] ?? "익명",
        "content": c["content"] ?? "",
        "likes": (int.tryParse((c["likeCount"] ?? 0).toString()) ?? 0).obs,
        "isCommentLiked": ((c["isLiked"] ?? false) as bool).obs,
        "replies": parsedReplies.obs,
      };
    }).toList();
  }

  Future<void> loadCommentsForPost(Map<String, dynamic> post) async {
    final String pId = post["id"].toString();
    try {
      final commentRes = await http.get(
        Uri.parse('$baseUrl/groups/posts/$pId/comments'),
        headers: _headers,
      ).catchError((_) => http.Response('{}', 404));

      if (commentRes.statusCode == 200) {
        final Map<String, dynamic> cData = jsonDecode(utf8.decode(commentRes.bodyBytes));
        final List rawComments = cData["comments"] is List ? cData["comments"] : [];

        final freshComments = parseCommentsList(rawComments);
        if (post["comments"] is RxList) {
          (post["comments"] as RxList).assignAll(freshComments);
        } else {
          post["comments"] = freshComments.obs;
        }
        if (post["comments"] is RxList) {
          (post["comments"] as RxList).refresh();
        }
      }
    } catch (_) {}
  }

  Future<void> refreshPostsOnly() async {
    final gId = currentGroupId.value;
    if (gId.isEmpty) return;

    Future<Map<String, dynamic>> _fetchPostDiscussionDetails(Map<String, dynamic> parsedPost) async {
      final String pId = parsedPost["id"].toString();
      try {
        final detailRes = await http.get(
          Uri.parse('$baseUrl/groups/posts/$pId'),
          headers: _headers,
        );
        if (detailRes.statusCode == 200) {
          final Map<String, dynamic> detailData = jsonDecode(utf8.decode(detailRes.bodyBytes));

          final List records = detailData["records"] is List ? detailData["records"] : [];
          if (records.isNotEmpty) {
            for (final record in records) {
              final String recordType = record["recordType"]?.toString() ?? "";
              final int recordId = int.tryParse(record["recordId"]?.toString() ?? "0") ?? 0;
              final int bookId = int.tryParse(detailData["bookId"]?.toString() ?? "0") ?? 0;

              if (recordType.isNotEmpty && recordId != 0 && bookId != 0) {
                final String listEndpoint = switch (recordType) {
                  "BOOKMARK"  => "/bookmarks/books/$bookId",
                  "HIGHLIGHT" => "/highlights/books/$bookId",
                  "NOTE"      => "/notes/books/$bookId",
                  _           => "",
                };

                if (listEndpoint.isNotEmpty) {
                  try {
                    final listRes = await http.get(
                      Uri.parse('$baseUrl$listEndpoint'),
                      headers: _headers,
                    );
                    if (listRes.statusCode == 200) {
                      final List rawList = jsonDecode(utf8.decode(listRes.bodyBytes));
                      final matched = rawList.firstWhere(
                            (item) => item["id"]?.toString() == recordId.toString(),
                        orElse: () => null,
                      );
                      if (matched != null) {
                        final List<Map<String, dynamic>> existing =
                        List<Map<String, dynamic>>.from(parsedPost["recordDataList"] ?? []);
                        existing.add({
                          "recordType": recordType,
                          "recordData": Map<String, dynamic>.from(matched),
                        });
                        parsedPost["recordDataList"] = existing;
                      }
                    }
                  } catch (_) {}
                }
              }
            }
          }

          if (detailData["recordType"] != null) {
            parsedPost["recordType"] = detailData["recordType"]?.toString();
            if (detailData["recordData"] is Map) {
              parsedPost["recordData"] = Map<String, dynamic>.from(detailData["recordData"]);
            }
          }

          final dynamic discussionObj = detailData["discussion"];
          if (discussionObj is Map && discussionObj.isNotEmpty) {
            parsedPost["discussion"] = discussionObj;
            parsedPost["hasPoll"] = true;
            parsedPost["isDiscussion"] = true;
            parsedPost["pollQuestion"] = discussionObj["question"]?.toString() ?? "";

            final List optionsRaw = discussionObj["options"] is List ? discussionObj["options"] : [];
            parsedPost["pollOptions"] = optionsRaw.map((e) => e["label"]?.toString() ?? "").toList();
            parsedPost["pollVotes"] = optionsRaw.map((e) => int.tryParse(e["voteCount"]?.toString() ?? "0") ?? 0).toList().obs;

            if (discussionObj["myVoteOptionId"] != null) {
              parsedPost["selectedOption"].value = (int.tryParse(discussionObj["myVoteOptionId"].toString()) ?? 0) - 1;
            }
          }
        }
      } catch (_) {}
      return parsedPost;
    }

    final missionPostRes = await http.get(
      Uri.parse('$baseUrl/groups/$gId/posts?type=MISSION'),
      headers: _headers,
    ).catchError((_) => http.Response('[]', 404));

    if (missionPostRes.statusCode == 200) {
      final dynamic rawM = jsonDecode(utf8.decode(missionPostRes.bodyBytes));
      List mData = (rawM is Map) ? (rawM['posts'] ?? []) : (rawM is List ? rawM : []);

      List<Map<String, dynamic>> parsedMission = [];
      for (var item in mData) {
        var postItem = _parsePostItem(item);
        postItem = await _fetchPostDiscussionDetails(postItem);
        parsedMission.add(postItem);
      }
      
      // 🚀 [핵심 수정]: 화면을 그리기 전에 모든 포스트의 댓글 조회를 비동기로 일제히 선로딩 완료 대기
      await Future.wait(parsedMission.map((post) => loadCommentsForPost(post)));
      
      missionPosts.assignAll(parsedMission);
      missionPosts.refresh();
    }

    final freePostRes = await http.get(
      Uri.parse('$baseUrl/groups/$gId/posts?type=FREE'),
      headers: _headers,
    ).catchError((_) => http.Response('[]', 404));

    if (freePostRes.statusCode == 200) {
      final dynamic rawF = jsonDecode(utf8.decode(freePostRes.bodyBytes));
      List fData = (rawF is Map) ? (rawF['posts'] ?? []) : (rawF is List ? rawF : []);

      List<Map<String, dynamic>> parsedFree = [];
      for (var item in fData) {
        var postItem = _parsePostItem(item);
        postItem = await _fetchPostDiscussionDetails(postItem);
        parsedFree.add(postItem);
      }
      
      // 🚀 [핵심 수정]: 화면을 그리기 전에 모든 포스트의 댓글 조회를 비동기로 일제히 선로딩 완료 대기
      await Future.wait(parsedFree.map((post) => loadCommentsForPost(post)));
      
      freePosts.assignAll(parsedFree);
      freePosts.refresh();
    }
  }

  Future<void> fetchFilteredBookBoard(String bookId, bool isMission) async {
    try {
      isLoading.value = true;
      final String typeParam = isMission ? "MISSION" : "FREE";
      final url = Uri.parse('$baseUrl/groups/${currentGroupId.value}/posts?type=$typeParam&bookId=$bookId');

      final response = await http.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final dynamic rawData = jsonDecode(utf8.decode(response.bodyBytes));
        List postData = (rawData is Map) ? (rawData['posts'] ?? []) : (rawData is List ? rawData : []);

        List<Map<String, dynamic>> parsedPosts = postData.map((item) => _parsePostItem(item)).toList();
        await Future.wait(parsedPosts.map((post) => loadCommentsForPost(post)));

        if (isMission) {
          missionPosts.assignAll(parsedPosts);
          missionPosts.refresh();
        } else {
          freePosts.assignAll(parsedPosts);
          freePosts.refresh();
        }
      }
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchHistoryBookBoard(Map<String, dynamic> historyBook) async {
    try {
      isLoading.value = true;
      historySelectedBookTitle.value = historyBook["title"] ?? "";
      historySelectedBookAuthor.value = historyBook["author"] ?? "";
      historySelectedBookCover.value = historyBook["cover"] ?? "";
      final String bId = historyBook["bookId"]?.toString() ?? "0";
      final response = await http.get(Uri.parse('$baseUrl/groups/${currentGroupId.value}/posts?type=MISSION&bookId=$bId'), headers: _headers);
      if (response.statusCode == 200) {
        final dynamic rawPosts = jsonDecode(utf8.decode(response.bodyBytes));
        List postData = (rawPosts is Map) ? (rawPosts['posts'] ?? []) : (rawPosts is List ? rawPosts : []);
        
        List<Map<String, dynamic>> parsedHistoryPosts = postData.map((item) => _parsePostItem(item)).toList();
        await Future.wait(parsedHistoryPosts.map((post) => loadCommentsForPost(post)));
        
        historyMissionPosts.assignAll(parsedHistoryPosts);
        historyMissionPosts.refresh();
      }
    } catch (_) {}
    finally { isLoading.value = false; }
  }

  Future<void> searchBooksFromAPI(String query) async {
    if (query.trim().isEmpty) { searchedBooksResult.clear(); return; }
    try {
      isSearching.value = true;
      final List<Book> books = await _searchRepository.searchBooks(query);
      searchedBooksResult.value = List.from(books);
    } catch (_) {}
    finally { isSearching.value = false; }
  }

  Future<bool> changeMissionBook(String isbn) async {
    try {
      final response = await http.patch(Uri.parse('$baseUrl/groups/${currentGroupId.value}/mission-book'), headers: _headers, body: jsonEncode({"isbn": isbn}));
      if (response.statusCode == 200 || response.statusCode == 204) { await fetchAllDataFromAPI(); return true; }
      return false;
    } catch (_) { return false; }
  }

  Future<bool> leaveGroup() async {
    try {
      isLoading.value = true;
      final url = Uri.parse('$baseUrl/groups/${currentGroupId.value}/leave');
      final response = await http.delete(url, headers: _headers);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteGroup() async {
    try {
      isLoading.value = true;
      final url = Uri.parse('$baseUrl/groups/${currentGroupId.value}');
      final response = await http.delete(url, headers: _headers);
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      isLoading.value = false;
    }
  }

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
        "records": attachedNotes.map((n) => {
          "recordType": _toRecordType(n["type"]),
          "recordId": n["data"]["id"],
        }).toList(),
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
    } catch (e) {
      print("❌ createNewPost Error: $e");
    } finally {
      removeAttachedBook();
      removeAttachedDiscussion();
      removeAttachedNote();
    }
  }

  Future<bool> addCommentToPost(dynamic postArg, String content) async {
    if (content.trim().isEmpty) return false;
    try {
      String postId = postArg is Map ? (postArg["id"]?.toString() ?? "0") : postArg.toString();
      final url = Uri.parse('$baseUrl/groups/posts/$postId/comments');
      final Map<String, dynamic> commentPayload = {
        "content": content
      };
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(commentPayload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await refreshPostsOnly();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addReplyToComment(String postId, dynamic commentArg, String content) async {
    if (content.trim().isEmpty) return false;
    try {
      String commentId = commentArg is Map ? (commentArg["id"]?.toString() ?? "0") : commentArg.toString();
      final url = Uri.parse('$baseUrl/groups/comments/$commentId/replies');
      final response = await http.post(url, headers: _headers, body: jsonEncode({"content": content}));
      if (response.statusCode == 200 || response.statusCode == 201) {
        await refreshPostsOnly();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> castVote(Map<String, dynamic> post, int optionIndex) async {
    try {
      await http.post(
          Uri.parse('$baseUrl/groups/posts/${post["id"]}/discussion/vote'),
          headers: _headers,
          body: jsonEncode({"optionId": optionIndex + 1})
      );
      await refreshPostsOnly();
    } catch (_) {}
  }

  Future<bool> addAnnouncement(String title, String content) async {
    if (title.trim().isEmpty || content.trim().isEmpty) return false;
    try {
      final url = Uri.parse('$baseUrl/groups/${currentGroupId.value}/announcements');
      final Map<String, dynamic> bodyData = {
        "type": "ANNOUNCEMENT",
        "title": title.trim(),
        "content": content.trim(),
        "bookId": null,
        "recordId": null,
      };
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(bodyData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchAllDataFromAPI();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
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
    if (comment["isCommentLiked"] is! RxBool || comment["likes"] is! RxInt) return;
    final RxBool rxIsLiked = comment["isCommentLiked"];
    final RxInt rxLikes = comment["likes"];
    final bool current = rxIsLiked.value;
    rxIsLiked.value = !current;
    if (rxIsLiked.value) { rxLikes.value++; } else { rxLikes.value--; }
    try {
      final url = Uri.parse('$baseUrl/groups/comments/${comment["id"]}/like');
      if (current) {
        await http.delete(url, headers: _headers);
      } else {
        await http.post(url, headers: _headers);
      }
    } catch (_) {}
  }

  Future<void> loadHistoryBookWithDetail(Map<String, dynamic> bookData) async {
    isLoading.value = true;

    // 1. 과거 게시글 리스트 API 통신 선행 호출
    await fetchHistoryBookBoard(bookData);

    // 2. 과거 보관함 명세서 규격에 따른 변수 기본 셋팅 (1차 백업 주소 연동)
    historySelectedBookTitle.value = bookData["title"]?.toString() ?? "제목 없음";
    historySelectedBookCover.value = bookData["thumbnail"]?.toString() ?? bookData["cover"]?.toString() ?? "";
    historySelectedBookAuthor.value = "저자 미상";

    // 3. 스웨거에 명시된 bookId 추출
    final int? targetBookId = int.tryParse(bookData["bookId"]?.toString() ?? "");

    if (targetBookId != null && targetBookId != 0) {
      try {
        final String targetUrl = "https://api.43-202-101-63.sslip.io/books/$targetBookId";
        final response = await http.get(Uri.parse(targetUrl));

        if (response.statusCode == 200) {
          final Map<String, dynamic> decodedData = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

          // 🎯 [완치 포인트 1]: 책 상세 API의 정품 thumbnail 주소를 인양하여 이미지 유실을 원천 차단합니다.
          final String detailThumbnail = decodedData["thumbnail"]?.toString() ??
              decodedData["small_thumbnail"]?.toString() ?? "";

          if (detailThumbnail.isNotEmpty) {
            historySelectedBookCover.value = detailThumbnail;
          }

          // 🎯 [완치 Point 2]: 저자명 리스트 첫 번째 요소 인양
          if (decodedData["authors"] != null && (decodedData["authors"] as List).isNotEmpty) {
            historySelectedBookAuthor.value = decodedData["authors"][0].toString();
            print("🎯 과거 도서 저자명 인양 완료: ${historySelectedBookAuthor.value}");
          }
        }
      } catch (e) {
        print("❌ 과거 도서 상세 데이터 인양 실패: $e");
      }
    }

    isLoading.value = false;
  }

  Future<void> togglePinAnnouncement(Map<String, dynamic> announcement) async {
    if (announcement["id"] == null) return;
    final bool currentStatus = announcement["isPinned"].value;

    try {
      announcement["isPinned"].value = !currentStatus;

      announcements.sort((a, b) {
        final bool aPinned = a["isPinned"].value;
        final bool bPinned = b["isPinned"].value;
        if (aPinned && !bPinned) return -1;
        if (!aPinned && bPinned) return 1;
        return 0;
      });
      announcements.refresh();

      final url = Uri.parse('$baseUrl/groups/posts/${announcement["id"]}/pin');
      final response = await http.patch(url, headers: _headers);

      if (response.statusCode != 200 && response.statusCode != 204) {
        announcement["isPinned"].value = currentStatus;
        announcements.sort((a, b) {
          final bool aPinned = a["isPinned"].value;
          final bool bPinned = b["isPinned"].value;
          if (aPinned && !bPinned) return -1;
          if (!aPinned && bPinned) return 1;
          return 0;
        });
        announcements.refresh();
      }
    } catch (e) {
      announcement["isPinned"].value = currentStatus;
      announcements.refresh();
    }
  }

  void deleteAnnouncement(Map<String, dynamic> announcement) async {
    try {
      await http.delete(Uri.parse('$baseUrl/groups/${currentGroupId.value}/announcements/${announcement["id"]}'), headers: _headers);
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

  Map<String, dynamic> _parsePostItem(dynamic item) {
    if (item == null) return {};
    final String postType = item["type"]?.toString() ?? "";
    final bool isMissionPost = (postType == "MISSION" || postType == "mission");
    final int baseLikes = int.tryParse((item["likeCount"] ?? item["likesCount"] ?? 0).toString()) ?? 0;
    final bool baseIsLiked = item["isLiked"] ?? false;
    final int parsedBookId = int.tryParse((item["id"] ?? item["bookId"])?.toString() ?? "0") ?? 0;

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

      "likes": baseLikes.obs,
      "isLiked": baseIsLiked.obs,
      "hasPoll": false,
      "isDiscussion": false,
      "pollQuestion": "",
      "pollOptions": <String>[],
      "pollVotes": <int>[].obs,
      "discussion": null,
      "selectedOption": (-1).obs,
      "comments": <Map<String, dynamic>>[].obs,

      "recordType": item["recordType"]?.toString(),
      "recordData": null,
      "recordDataList": <Map<String, dynamic>>[],
    };
  }

  void attachNote(String itemType, Map<String, dynamic> itemData) {
    attachedNotes.add({
      "type": itemType,
      "data": itemData,
    });
  }

  void removeAttachedNote({int? index}) {
    if (index != null) {
      attachedNotes.removeAt(index);
    } else {
      attachedNotes.clear();
    }
  }

  String _toRecordType(String itemType) {
    switch (itemType) {
      case "bookmark":  return "BOOKMARK";
      case "highlight": return "HIGHLIGHT";
      case "memo":      return "NOTE";
      default:          return "NOTE";
    }
  }
}