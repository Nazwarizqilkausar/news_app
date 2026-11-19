import 'package:dio/dio.dart';

import '../config/env.dart';

/// Semua teks error di satu tempat (tidak diulang di mana-mana).
class PesanError {
  PesanError._();

  static const timeout =
      'Server lagi tidur siang, belum bangun. Coba lagi sebentar ya.';
  static const tanpaInternet =
      'Wi-Fi-nya kabur bawa nasi goreng! Periksa koneksi internet Anda.';
  static const sertifikat = 'Sertifikat keamanan server tidak valid.';
  static const dibatalkan = 'Permintaan dibatalkan.';
  static const keyBermasalah =
      'Kunci dapur salah atau tidak terdaftar (API key).';
  static const kuotaHabis =
      'Stok dapur habis! Kuota harian habis atau email akun belum diverifikasi.';
  static const endpointHilang =
      'Alamat dapur tidak ditemukan (endpoint salah).';
  static const terlaluCepat =
      'Pelan-pelan, kokinya belum selesai masak! '
      'Paket gratis hanya 1 request per detik.';
  static const dataAneh = 'Format data dari server tidak dikenali.';
  static const strukturBeda = 'Struktur data dari server berbeda dari model.';
  static const konfigKosong =
      'Konfigurasi belum diisi. Jalankan dengan '
      '--dart-define-from-file=config/env.json';
  static const kataKunciKosong = 'Kata kunci pencarian tidak boleh kosong.';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  factory ApiException.fromDio(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => ApiException(PesanError.timeout),
      DioExceptionType.connectionError => ApiException(
        PesanError.tanpaInternet,
      ),
      DioExceptionType.badCertificate => ApiException(PesanError.sertifikat),
      DioExceptionType.cancel => ApiException(PesanError.dibatalkan),
      DioExceptionType.badResponse => _dariResponse(e.response),
      DioExceptionType.unknown => ApiException(
        'Terjadi kesalahan tak terduga: ${Env.samarkan(e.message ?? '-')}',
      ),
    };
  }

  /// GNews mengirim {"errors": ["pesan"]} atau {"errors": {"q": "pesan"}}
  static ApiException _dariResponse(Response<dynamic>? response) {
    final code = response?.statusCode;
    final pesanServer = _ambilPesanServer(response?.data);

    final pesan = switch (code) {
      400 => 'Permintaan tidak valid. ${pesanServer ?? ''}',
      401 => PesanError.keyBermasalah,
      403 => PesanError.kuotaHabis,
      404 => PesanError.endpointHilang,
      429 => PesanError.terlaluCepat,
      final c? when c >= 500 => 'Server GNews sedang bermasalah ($c).',
      _ => 'Gagal memuat data (kode ${code ?? '-'}).',
    };
    return ApiException(pesan.trim(), statusCode: code);
  }

  static String? _ambilPesanServer(dynamic data) {
    if (data is! Map) {
      return null;
    }
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors.first.toString();
    }
    if (errors is Map && errors.isNotEmpty) {
      return errors.values.first.toString();
    }
    return null;
  }

  @override
  String toString() => message;
}
