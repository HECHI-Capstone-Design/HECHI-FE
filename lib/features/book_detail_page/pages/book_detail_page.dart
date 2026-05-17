import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../controllers/book_detail_controller.dart';
import '../widgets/book_cover_Header.dart';
import '../widgets/book_info_section.dart';
import '../widgets/action_buttons.dart';
import '../widgets/author_section.dart';
import '../widgets/comment_section.dart';
import '../widgets/meta_info_section.dart';
import '../widgets/book_collection_section.dart';
import '../../../core/widgets/bottom_bar.dart';

class BookDetailPage extends StatefulWidget {
  const BookDetailPage({super.key});
  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final scrollController = ScrollController();
  double opacity = 0.0;
  bool _isStatusDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      double offset = scrollController.offset;
      double newOpacity = ((offset - 200) / 100).clamp(0.0, 1.0);
      setState(() => opacity = newOpacity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookDetailController>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(opacity),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Opacity(
          opacity: opacity,
          child: Obx(() => Text(
            controller.book["title"] ?? "",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          )),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: opacity > 0.5 ? Colors.black : Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 17),
            child: GestureDetector(
              onTap: controller.openMoreMenu,
              child: Icon(
                Icons.more_horiz,
                color: opacity > 0.5 ? Colors.black : Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const BottomBar(),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BookCoverHeader(),
              const BookInfoSection(),
              const Divider(thickness: 1, color: Color(0xFFF5F5F5)),
              const ActionButtons(),
              _buildReadingStatusDropdown(controller),
              const SizedBox(height: 12),
              _buildInteractiveRatingBar(),
              const SizedBox(height: 12),
              Container(height: 8, color: const Color(0xFFF5F5F5)),
              const MetaInfoSection(),
              Container(height: 8, color: const Color(0xFFF5F5F5)),
              const AuthorSection(),
              Container(height: 8, color: const Color(0xFFF5F5F5)),
              const CommentSection(),
              Container(height: 8, color: const Color(0xFFF5F5F5)),
              const BookCollectionSection(),
              Container(height: 8, color: const Color(0xFFF5F5F5)),
            ],
          ),
        );
      }),
    );
  }

  // 독서 상태 드롭다운
  Widget _buildReadingStatusDropdown(BookDetailController controller) {
    return Obx(() {
      final status = controller.readingStatus.value;

      String label;
      switch (status) {
        case 'READING':
          label = '읽는 중';
          break;
        case 'COMPLETED':
          label = '완독함';
          break;
        default:
          label = '독서 상태';
      }

      return Padding(
        padding: const EdgeInsets.only(top: 10, left: 17, right: 17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => setState(() => _isStatusDropdownOpen = !_isStatusDropdownOpen),
              child: Container(
                width: double.infinity,
                height: 35,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: ShapeDecoration(
                  color: (status == 'READING' || status == 'COMPLETED')
                      ? const Color(0x4CD1ECD9)
                      : const Color(0x4CD4D4D4),
                  shape: RoundedRectangleBorder(
                    borderRadius: _isStatusDropdownOpen
                        ? const BorderRadius.vertical(top: Radius.circular(4))
                        : BorderRadius.circular(4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF717171),
                        fontSize: 15,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                        height: 1.33,
                        letterSpacing: 0.25,
                      ),
                    ),
                    Icon(
                      _isStatusDropdownOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF717171),
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),

            if (_isStatusDropdownOpen)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    left: BorderSide(width: 1, color: Color(0xFFD4D4D4)),
                    right: BorderSide(width: 1, color: Color(0xFFD4D4D4)),
                    bottom: BorderSide(width: 1, color: Color(0xFFD4D4D4)),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    _buildStatusItem('읽는 중', 'READING', status, controller),
                    _buildStatusItem('완독함', 'COMPLETED', status, controller),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildStatusItem(
      String label,
      String value,
      String currentStatus,
      BookDetailController controller,
      ) {
    final isSelected = currentStatus == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final nextStatus = currentStatus == value ? 'PENDING' : value;
        controller.updateReadingStatus(nextStatus);
        setState(() => _isStatusDropdownOpen = false);
      },
      child: Container(
        width: double.infinity,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF3F3F3F),
                fontSize: 15,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w400,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 18, color: Color(0xFF4DB56C)),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveRatingBar() {
    final controller = Get.find<BookDetailController>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17,),
      alignment: Alignment.center,
      child: Obx(() => RatingBar(
        initialRating: controller.myRating.value,
        minRating: 0.0,
        allowHalfRating: true,
        itemCount: 5,
        itemPadding: const EdgeInsets.symmetric(horizontal: 2),
        ratingWidget: RatingWidget(
          full: const Icon(Icons.star, color: Color(0xFFFFD700)),
          half: const Icon(Icons.star_half, color: Color(0xFFFFD700)),
          empty: const Icon(Icons.star, color: Color(0xFFD4D4D4)),
        ),
        glow: false,
        onRatingUpdate: (rating) {
          controller.myRating.value = rating;
          controller.submitRating(rating);
        },
      )),
    );
  }
}
