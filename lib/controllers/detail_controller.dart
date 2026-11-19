import 'package:get/get.dart';

import '../models/article_model.dart';

class DetailController extends GetxController {
  /// Artikel dikirim dari HomeView lewat Get.toNamed(arguments: article)
  late final ArticleModel article;

  @override
  void onInit() {
    super.onInit();
    article = Get.arguments as ArticleModel;
  }
}
