import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hechi/app/theme.dart';
import 'package:hechi/app/routes.dart';
import 'package:hechi/app/controllers/app_controller.dart';
import 'package:hechi/core/widgets/bottom_bar.dart';
import '../features/mainpage/pages/mainpage_view.dart';
import '../features/my_read/pages/my_read_view.dart';
import '../features/search/pages/search_view.dart';
import '../features/reading_registration/pages/reading_registration_view.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'HECHI',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.initial,
      getPages: AppPages.pages,
    );
  }
}

class MainWrapper extends GetView<AppController> {
  const MainWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Obx(() => IndexedStack(
          index: controller.currentIndex.value,
          children: [
            const MainpageView(),
            const SearchView(),
            const ReadingRegistrationView(),            
            _buildPlaceholder("리워드 페이지"),
            MyReadView(),
          ],
        )),
      ),
      bottomNavigationBar: const BottomBar(),
    );
  }

  Widget _buildPlaceholder(String text) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 20, color: Colors.grey),
        ),
      ),
    );
  }
}