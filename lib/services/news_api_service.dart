import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import '../models/article_model.dart';
import '../models/news_response_model.dart';
import 'api_exception.dart';

/// URL dan API key TIDAK ditulis di sini, tetapi dibaca dari Env.
class NewsApiService {
  final Dio _dio;

  NewsApiService({Dio? dio}) : _dio = dio ?? _buatDio();

  static Dio _buatDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        queryParameters: {
          'apikey': Env.apiKey,
          'lang': 'id',
          'country': 'id',
          'max': 10,
        },
      ),
    );

    // Log hanya saat debug; API key disamarkan menjadi ***
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          responseBody: true,
          logPrint: (obj) => debugPrint(Env.samarkan(obj.toString())),
        ),
      );
    }
    return dio;
  }

  Future<List<ArticleModel>> getTopHeadlines({String category = 'general'}) {
    return _ambilArtikel('/top-headlines', {'category': category});
  }

  /// Method UTAMA untuk tema kuliner: semua chip memanggil ini.
  Future<List<ArticleModel>> searchNews(String keyword) async {
    if (keyword.trim().isEmpty) {
      throw ApiException(PesanError.kataKunciKosong);
    }
    return _ambilArtikel('/search', {
      'q': keyword.trim(),
      'sortby': 'publishedAt',
    });
  }

  /// Satu pintu untuk semua GET: di sinilah error diterjemahkan.
  Future<List<ArticleModel>> _ambilArtikel(
    String path,
    Map<String, dynamic> query,
  ) async {
    if (!Env.lengkap) {
      throw ApiException(PesanError.konfigKosong);
    }

    try {
      final response = await _dio.get(path, queryParameters: query);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(PesanError.dataAneh);
      }
      return NewsResponseModel.fromJson(data).articles;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } on TypeError {
      throw ApiException(PesanError.strukturBeda);
    }
  }
}
