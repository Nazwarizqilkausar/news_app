import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/article_model.dart';
import '../routes/app_routes.dart';
import '../services/news_api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/article_card.dart';
import '../widgets/error_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final NewsApiService _service = NewsApiService();

  // Chip kuliner: kata kunci untuk /search
  static const List<String> _keywords = [
    'kuliner',
    'nasi goreng',
    'bakso',
    'cafe',
    'viral makanan',
    'jajanan',
  ];

  String _selectedKeyword = _keywords.first;

  /// LATIHAN 2: cache kata kunci -> Future hasilnya (hemat kuota)
  final Map<String, Future<List<ArticleModel>>> _cache = {};

  /// Future disimpan di State, BUKAN dibuat di dalam build()
  late Future<List<ArticleModel>> _futureNews;

  @override
  void initState() {
    super.initState();
    _futureNews = _ambilDariCache(_selectedKeyword);
  }

  /// Pakai Future lama bila ada; bila belum ada, buat baru dan simpan.
  Future<List<ArticleModel>> _ambilDariCache(String keyword) {
    return _cache.putIfAbsent(keyword, () {
      final future = _service.searchNews(keyword);
      // Bila gagal, jangan disimpan agar bisa dicoba lagi
      future.catchError((_) {
        _cache.remove(keyword);
        return <ArticleModel>[];
      });
      return future;
    });
  }

  /// Dipakai tombol Coba Lagi dan pull-to-refresh: buang cache, minta baru.
  void _muatUlang() {
    setState(() {
      _cache.remove(_selectedKeyword);
      _futureNews = _ambilDariCache(_selectedKeyword);
    });
  }

  void _gantiKeyword(String keyword) {
    if (keyword == _selectedKeyword) {
      return;
    }
    setState(() {
      _selectedKeyword = keyword;
      _futureNews = _ambilDariCache(keyword);
    });
  }

  /// Untuk RefreshIndicator: tunggu sampai request selesai
  Future<void> _onRefresh() async {
    _muatUlang();
    try {
      await _futureNews;
    } catch (_) {
      // error sudah ditampilkan oleh FutureBuilder
    }
  }

  /// LATIHAN 1: dialog input kata kunci, lalu buka halaman hasil
  Future<void> _bukaDialogCari() async {
    final controller = TextEditingController();

    final keyword = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cari berita kuliner'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Contoh: sate padang'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Cari'),
          ),
        ],
      ),
    );
    controller.dispose();

    final teks = keyword?.trim() ?? '';
    if (teks.isEmpty) {
      return;
    }
    Get.toNamed(AppRoutes.search, arguments: teks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berita Perut Lapar 🍜'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Cari berita',
            onPressed: _bukaDialogCari,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildChips(),
          Expanded(
            child: FutureBuilder<List<ArticleModel>>(
              future: _futureNews,
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
                  return const Center(
                    child: Text('Tidak ada berita. Kokinya lagi istirahat.'),
                  );
                }

                // 4. DATA
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return ArticleCard(
                        article: article,
                        onTap: () =>
                            Get.toNamed(AppRoutes.detail, arguments: article),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChips() {
    return Container(
      height: 56,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _keywords.length,
        itemBuilder: (context, index) {
          final keyword = _keywords[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ChoiceChip(
              label: Text(keyword),
              selected: keyword == _selectedKeyword,
              onSelected: (_) => _gantiKeyword(keyword),
            ),
          );
        },
      ),
    );
  }
}
