import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  /// Mengubah "2026-11-18T13:20:45Z" menjadi "18 Nov 2026".
  /// Bila gagal diparse, teks aslinya dikembalikan.
  static String formatDate(String iso) {
    if (iso.isEmpty) {
      return '-';
    }
    try {
      final tanggal = DateTime.parse(iso).toLocal();
      return DateFormat('d MMM yyyy', 'id_ID').format(tanggal);
    } catch (_) {
      return iso;
    }
  }
}
