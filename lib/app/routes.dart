import 'package:get/get.dart';
import 'package:hechi/app/main_app.dart';
import 'package:hechi/features/collection/bindings/add_to_collection_binding.dart';
import 'package:hechi/features/collection/bindings/book_collection_list_binding.dart';
import 'package:hechi/features/collection_detail/bindings/collection_detail_binding.dart';
import 'package:hechi/features/customer_service/pages/customer_service_page.dart';
import 'package:hechi/app/bindings/app_binding.dart';
import '../features/login/bindings/login_binding.dart';
import '../features/login/pages/login_view.dart';
import '../features/sign_up/bindings/sign_up_binding.dart';
import '../features/sign_up/pages/sign_up_view.dart';
import '../features/forget_password/bindings/forget_password_binding.dart';
import '../features/forget_password/pages/forget_password_view.dart';

import '../features/preference/bindings/preference_binding.dart';
import '../features/preference/pages/preference_view.dart';
import '../features/taste_analysis/bindings/taste_analysis_binding.dart';
import '../features/taste_analysis/pages/taste_analysis_view.dart';

import '../features/search/pages/search_view.dart';
import '../features/search/pages/isbn_scan_view.dart';
import '../features/book_detail_page/bindings/book_detail_binding.dart';
import '../features/book_detail_page/pages/book_detail_page.dart';
import '../features/reading_detail/bindings/reading_detail_binding.dart';
import '../features/reading_detail/pages/reading_detail_view.dart';
import '../features/book_storage/pages/book_storage_view.dart';
import '../features/book_storage/bindings/book_storage_binding.dart';

import '../features/splash/pages/splash_view.dart';
import '../features/settings/pages/settings_view.dart';
import '../features/settings/bindings/settings_binding.dart';

import '../features/review_list/bindings/review_list_binding.dart';
import '../features/review_list/pages/review_list_page.dart';
import '../features/review_detail/bindings/review_detail_binding.dart';
import '../features/review_detail/pages/review_detail_page.dart';

import '../features/calendar/pages/calendar_view.dart';
import '../features/calendar/bindings/calendar_binding.dart';

import '../features/book_note/bindings/book_note_binding.dart';
import '../features/book_note/pages/book_note_page.dart';
import '../features/reading_registration/bindings/reading_registration_binding.dart';
import '../features/reading_registration/pages/reading_registration_view.dart';
import '../features/recommendation/pages/recommendation_view.dart';
import '../features/recommendation/bindings/recommendation_binding.dart';

// ✅ 이메일 인증 바인딩 및 뷰 임포트 추가
import '../features/email_verify/bindings/email_verify_binding.dart';
import '../features/email_verify/pages/email_verify_view.dart';

import '../features/collection/bindings/collection_list_binding.dart';
import '../features/collection/pages/collection_list_page.dart';
import '../features/collection/bindings/create_collection_binding.dart';
import '../features/collection/pages/create_collection_page.dart';
import '../features/collection/bindings/collection_book_edit_binding.dart';
import '../features/collection/pages/collection_book_edit_page.dart';
import '../features/collection/pages/add_to_collection_page.dart';
import '../features/collection/pages/book_collection_list_page.dart';
import '../features/collection_detail/pages/collection_detail_view.dart';

import '../features/myGroup/pages/my_group_page.dart';
import '../features/myGroup/pages/group_recommendation_page.dart';
import '../features/myGroup/bindings/my_group_binding.dart';
import '../features/myGroup/bindings/group_recommendation_binding.dart';
import '../features/myGroup/pages/group_create_page.dart';
import '../features/myGroup/bindings/group_create_binding.dart';

import 'package:hechi/features/groupcommunity/bindings/group_binding.dart';
import 'package:hechi/features/groupcommunity/pages/group_main_view.dart';
import 'package:hechi/features/groupcommunity/pages/group_menu_view.dart';
import 'package:hechi/features/groupcommunity/pages/group_member_list_view.dart';
import 'package:hechi/features/groupcommunity/pages/group_mission_history_view.dart';
import 'package:hechi/features/groupcommunity/pages/group_announcement_write_view.dart';
import 'package:hechi/features/groupcommunity/pages/group_post_list_view.dart';

import 'package:hechi/features/reward/bindings/reward_binding.dart';
import 'package:hechi/features/reward/pages/reward_page.dart';

abstract class Routes {
  static const splash = '/splash';
  static const initial = '/';
  static const customer = '/customer';
  static const login = '/login';
  static const signUp = '/sign_up';
  static const forgetPassword = '/forget_password';
  static const settings = '/settings';
  static const preference = '/preference';

  static const search = '/search';
  static const isbnScan = '/isbn_scan';
  static const bookDetailPage = '/book_detail_page';
  static const readingDetail = '/reading_detail';

  static const tasteAnalysis = '/taste_analysis';

  static const bookStorage = '/book_storage';

  static const reviewList = '/review_list';
  static const reviewDetail = '/review_detail';

  static const calendar = '/calendar';

  static const bookNote = '/book_note';
  static const readingRegistration = '/reading_registration';
  static const recommendation = '/recommendation';

  // ✅ 이메일 인증 라우트 추가
  static const emailVerify = '/email_verify';

  static const collectionList = '/collection_list';
  static const createCollection = '/create_collection';
  static const collectionBookEdit = '/collection/book_edit';
  static const addToCollection = '/collection/add';
  static const bookCollectionList = '/book_collection_list';
  static const collectionDetail = '/collection_detail';

  static const myGroup = '/myGroup';
  static const groupRecommendation = '/groupRecommendation';
  static const groupCreate = '/groupCreate';

 static const groupMain = '/group/main';
  static const groupMenu = '/group/menu';
  static const groupMembers = '/group/members';
  static const groupMissionHistory = '/group/mission-history';
  static const groupAnnouncementWrite = '/group/announcement/write';
  static const groupBoardMission = '/group/board/mission';
  static const groupBoardFree = '/group/board/free';

  static const reward = '/reward';
}

class AppPages {
  static final pages = [
    GetPage(name: Routes.splash, page: () => const SplashView()),
    GetPage(name: Routes.initial, page: () => const MainWrapper(), binding: AppBinding()),
    GetPage(name: Routes.customer, page: () => CustomerServicePage()),

    GetPage(name: Routes.login, page: () => const LoginView(), binding: LoginBinding()),
    GetPage(name: Routes.signUp, page: () => const SignUpView(), binding: SignUpBinding()),
    GetPage(name: Routes.forgetPassword, page: () => const ForgetPasswordView(), binding: ForgetPasswordBinding()),

    GetPage(name: Routes.preference, page: () => const PreferenceView(), binding: PreferenceBinding()),
    GetPage(name: Routes.search, page: () => const SearchView()),
    GetPage(name: Routes.isbnScan, page: () => const IsbnScanView()),
    GetPage(name: Routes.bookDetailPage, page: () => const BookDetailPage(), binding: BookDetailBinding()),
    GetPage(name: Routes.readingDetail, page: () => const ReadingDetailView(), binding: ReadingDetailBinding()),

    GetPage(name: Routes.tasteAnalysis, page: () => const TasteAnalysisView(), binding: TasteAnalysisBinding()),
    GetPage(name: Routes.settings, page: () => const SettingsView(), binding: SettingsBinding()),
    GetPage(name: Routes.bookStorage, page: () => const BookStorageView(), binding: BookStorageBinding()),

    GetPage(name: Routes.reviewList, page: () => const ReviewListPage(), binding: ReviewListBinding()),
    GetPage(name: Routes.reviewDetail, page: () => const ReviewDetailPage(), binding: ReviewDetailBinding()),
    GetPage(name: Routes.calendar, page: () => const CalendarView(), binding: CalendarBinding()),

    GetPage(name: Routes.bookNote, page: () => const BookNotePage(), binding: BookNoteBinding()),
    GetPage(name: Routes.readingRegistration, page: () => const ReadingRegistrationView(), binding: ReadingRegistrationBinding()),
    GetPage(name: Routes.recommendation, page: () => const RecommendationView(), binding: RecommendationBinding()),

    // ✅ 이메일 인증 페이지 등록
    GetPage(name: Routes.emailVerify, page: () => const EmailVerifyView(), binding: EmailVerifyBinding()),

    GetPage(name: Routes.collectionList, page: () => const CollectionListPage(), binding: CollectionListBinding()),
    GetPage(name: Routes.createCollection, page: () => const CreateCollectionPage(), binding: CreateCollectionBinding()),
    GetPage(name: Routes.collectionBookEdit, page: () => const CollectionBookEditPage(), binding: CollectionBookEditBinding()),
    GetPage(name: Routes.addToCollection, page: () => const AddToCollectionPage(), binding: AddToCollectionBinding()),
    GetPage(name: Routes.bookCollectionList, page: () => const BookCollectionListPage(), binding: BookCollectionListBinding()),
    GetPage(name: Routes.collectionDetail, page: () => const CollectionDetailView(), binding: CollectionDetailBinding()),

    GetPage(name: Routes.myGroup, page: () => const MyGroupPage(), binding: MyGroupBinding(),),
    GetPage(name: Routes.groupRecommendation, page: () => const GroupRecommendationPage(), binding: GroupRecommendationBinding(),),
    GetPage(name: Routes.groupCreate, page: () => const GroupCreatePage(), binding: GroupCreateBinding()),

    GetPage(name: Routes.groupMain, page: () => const GroupMainView(), binding: GroupBinding()),
    GetPage(name: Routes.groupMenu, page: () => const GroupMenuView()),
    GetPage(name: Routes.groupMembers, page: () => const GroupMemberListView()),
    GetPage(name: Routes.groupMissionHistory, page: () => const GroupMissionHistoryView()),
    GetPage(name: Routes.groupAnnouncementWrite, page: () => const GroupAnnouncementWriteView()),
    GetPage(name: Routes.groupBoardMission, page: () => const GroupPostListView(isMissionBoard: true)),
    GetPage(name: Routes.groupBoardFree, page: () => const GroupPostListView(isMissionBoard: false)),
   
   GetPage(name: Routes.reward, page: () => const RewardPage(), binding: RewardBinding()),
    ];
}