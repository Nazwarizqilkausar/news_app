import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/article_model.dart';
import '../routes/app_routes.dart';
import '../services/news_api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/article_card.dart';
import '../widgets/error_view.dart';

class SearchView extends StatefulWidget {
  final String keyword;

  const SearchView({super.key, required this.keyword});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final NewsApiService _service = NewsApiService();

  /// Disimpan di State, dibuat di initState(), BUKAN di build()
  late Future<List<ArticleModel>> _futureResult;

  @override
  void initState() {
    super.initState();
    _futureResult = _service.searchNews(widget.keyword);
  }

  void _muatUlang() {
    setState(() {
      _futureResult = _service.searchNews(widget.keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasil: ${widget.keyword}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ArticleModel>>(
        future: _futureResult,
        builder: (context, snapshot) {
          // 1. LOADING
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. ERROR
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: _muatUlang,
            );
          }

          // 3. KOSONG
          final articles = snapshot.data ?? [];
          if (articles.isEmpty) {
            return Center(
              child: Text('Tidak ada berita untuk "${widget.keyword}".'),
            );
          }

          // 4. DATA
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              return ArticleCard(
                article: article,
                onTap: () => Get.toNamed(AppRoutes.detail, arguments: article),
              );
            },
          );
        },
      ),
    );
  }
}
