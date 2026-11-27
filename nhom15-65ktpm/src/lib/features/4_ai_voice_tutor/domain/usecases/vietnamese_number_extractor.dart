import 'package:equatable/equatable.dart';

enum ExtractionType {
  number,
  unknown, // Trẻ nói từ chối / không biết (ví dụ: "con không biết", "chịu", "khó quá")
  unrecognized, // Chuỗi không nhận diện được số hợp lệ
  empty,
}

class ExtractionResult extends Equatable {
  final ExtractionType type;
  final int? value;
  final String rawSpeech;
  final String normalizedSpeech;

  const ExtractionResult({
    required this.type,
    this.value,
    required this.rawSpeech,
    required this.normalizedSpeech,
  });

  const ExtractionResult.number({
    required int value,
    required String rawSpeech,
    required String normalizedSpeech,
  }) : this(
          type: ExtractionType.number,
          value: value,
          rawSpeech: rawSpeech,
          normalizedSpeech: normalizedSpeech,
        );

  const ExtractionResult.unknown({
    required String rawSpeech,
    required String normalizedSpeech,
  }) : this(
          type: ExtractionType.unknown,
          value: null,
          rawSpeech: rawSpeech,
          normalizedSpeech: normalizedSpeech,
        );

  const ExtractionResult.unrecognized({
    required String rawSpeech,
    required String normalizedSpeech,
  }) : this(
          type: ExtractionType.unrecognized,
          value: null,
          rawSpeech: rawSpeech,
          normalizedSpeech: normalizedSpeech,
        );

  const ExtractionResult.empty({
    required String rawSpeech,
  }) : this(
          type: ExtractionType.empty,
          value: null,
          rawSpeech: rawSpeech,
          normalizedSpeech: '',
        );

  bool get isNumber => type == ExtractionType.number;
  bool get isUnknown => type == ExtractionType.unknown;
  bool get isUnrecognized => type == ExtractionType.unrecognized;
  bool get isEmpty => type == ExtractionType.empty;

  @override
  List<Object?> get props => [type, value, rawSpeech, normalizedSpeech];
}

/// Bộ phân tích và trích xuất số tiếng Việt cho trẻ em:
/// 1. Chuẩn hóa & loại bỏ từ đệm, từ xưng hô lễ phép ("dạ", "thưa cô", "thưa thầy", "cô ơi", "ơi", "kết quả là", "đáp án là", "bằng", "là", "cho con hỏi", "số"...)
/// 2. Bóc tách số dạng chữ số (-999 đến 9999) & số dạng chữ (hàng chục, hàng trăm, hàng nghìn, phương ngữ như "lăm", "nhăm", "mốt", "hăm mốt", "tư", "linh", "lẻ", số âm "âm năm" / "-5")
/// 3. Nhận diện các câu từ chối / chưa biết ("con không biết", "chịu", "khó quá", "bỏ qua") để trả về ExtractionResult.unknown và kích hoạt gợi ý (hint) thay vì tính là câu trả lời sai
class VietnameseNumberExtractor {
  static const Map<String, int> _unitWords = {
    'không': 0,
    'mot': 1,
    'một': 1,
    'mốt': 1,
    'hai': 2,
    'ba': 3,
    'bon': 4,
    'bốn': 4,
    'tư': 4,
    'nam': 5,
    'năm': 5,
    'lăm': 5,
    'nhăm': 5,
    'sau': 6,
    'sáu': 6,
    'bay': 7,
    'bảy': 7,
    'bẩy': 7,
    'tam': 8,
    'tám': 8,
    'chin': 9,
    'chín': 9,
  };

  /// Trích xuất chi tiết kết quả xử lý chuỗi transcript tiếng Việt
  static ExtractionResult extract(String rawSpeech) {
    if (rawSpeech.trim().isEmpty) {
      return ExtractionResult.empty(rawSpeech: rawSpeech);
    }

    // 1. Chuẩn hóa văn bản cơ bản
    String normalized = rawSpeech
        .toLowerCase()
        .replaceAll(RegExp(r'[,.?!;:]'), ' ')
        .trim();

    // 2. Kiểm tra mẫu từ chối / không biết của trẻ em -> Kích hoạt gợi ý (Hint)
    final refusalPatterns = [
      'không biết',
      'con không biết',
      'chưa biết',
      'không nhớ',
      'không rõ',
      'không hiểu',
      'con không hiểu',
      'chịu',
      'con chịu',
      'chịu thôi',
      'khó quá',
      'khó thế',
      'khó vậy',
      'bỏ qua',
      'qua câu khác',
      'chưa tính ra',
      'chưa tính được',
      'không làm được',
      'con không làm được',
      'không giải được',
    ];

    for (final pattern in refusalPatterns) {
      if (normalized.contains(pattern)) {
        return ExtractionResult.unknown(
          rawSpeech: rawSpeech,
          normalizedSpeech: normalized,
        );
      }
    }

    // 3. Kiểm tra nếu có chữ số trực tiếp trong câu (ví dụ STT trả về "15", "bằng 25", "-5", "âm 5")
    final digitMatch = RegExp(r'(?:(?:âm|trừ|-)\s*(\d+))|(-?\d+)').firstMatch(rawSpeech.toLowerCase());
    if (digitMatch != null) {
      if (digitMatch.group(1) != null) {
        final parsed = int.tryParse(digitMatch.group(1)!);
        if (parsed != null) {
          return ExtractionResult.number(
            value: -parsed,
            rawSpeech: rawSpeech,
            normalizedSpeech: normalized,
          );
        }
      } else if (digitMatch.group(2) != null) {
        final parsed = int.tryParse(digitMatch.group(2)!);
        if (parsed != null) {
          return ExtractionResult.number(
            value: parsed,
            rawSpeech: rawSpeech,
            normalizedSpeech: normalized,
          );
        }
      }
    }

    // 4. Nhận diện số âm dạng chữ ("âm năm", "trừ năm", "âm mười lăm"...)
    bool isNegative = false;
    final paddedCheck = ' $normalized ';
    if (paddedCheck.contains(' âm ') ||
        paddedCheck.contains(' trừ ') ||
        paddedCheck.contains(' - ') ||
        normalized.startsWith('-')) {
      isNegative = true;
      normalized = paddedCheck
          .replaceAll(' âm ', ' ')
          .replaceAll(' trừ ', ' ')
          .replaceAll(' - ', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    // 5. Chuẩn hóa các biến thể phương ngữ thông dụng
    // "hăm mốt" -> "hai mươi mốt", "hăm nhăm" -> "hai mươi lăm", "hăm" -> "hai mươi"
    normalized = normalized.replaceAll('hăm mốt', 'hai mươi mốt');
    normalized = normalized.replaceAll('hăm nhăm', 'hai mươi lăm');
    normalized = normalized.replaceAll('hăm lăm', 'hai mươi lăm');
    normalized = normalized.replaceAll('hăm tư', 'hai mươi bốn');
    normalized = normalized.replaceAllMapped(
      RegExp(r'\bhăm\b'),
      (match) => 'hai mươi',
    );

    // 6. Loại bỏ từ đệm, từ xưng hô thông dụng của trẻ em
    // Sắp xếp giảm dần theo độ dài để tránh cắt cụm từ
    final fillerWords = [
      'dạ thưa cô bằng',
      'dạ thưa thầy bằng',
      'thưa cô bằng',
      'thưa thầy bằng',
      'dạ thưa cô',
      'dạ thưa thầy',
      'cho con hỏi',
      'kết quả là bằng',
      'đáp án là bằng',
      'kết quả là',
      'đáp án là',
      'kết quả bằng',
      'đáp án bằng',
      'con tính ra',
      'em tính ra',
      'con nghĩ là',
      'con tính là',
      'thưa cô',
      'thưa thầy',
      'chào cô',
      'chào thầy',
      'cô ơi',
      'thầy ơi',
      'ơi cô',
      'ơi thầy',
      'kết quả',
      'đáp án',
      'dạ cô',
      'dạ thầy',
      'ạ cô',
      'ạ thầy',
      'con nghĩ',
      'nè cô',
      'bằng',
      'thưa',
      'cháu',
      'con',
      'em',
      'nhé',
      'nè',
      'dạ',
      'ạ',
      'ơi',
      'là',
      'số',
      'câu',
    ];

    String padded = ' $normalized ';
    for (final filler in fillerWords) {
      while (padded.contains(' $filler ')) {
        padded = padded.replaceAll(' $filler ', ' ');
      }
    }
    normalized = padded.replaceAll(RegExp(r'\s+'), ' ').trim();

    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return ExtractionResult.empty(rawSpeech: rawSpeech);
    }

    // 7. Phân tích ngữ nghĩa số tiếng Việt
    final parsedValue = _parseTokens(tokens);
    if (parsedValue != null) {
      final finalVal = isNegative ? -parsedValue : parsedValue;
      return ExtractionResult.number(
        value: finalVal,
        rawSpeech: rawSpeech,
        normalizedSpeech: normalized,
      );
    }

    return ExtractionResult.unrecognized(
      rawSpeech: rawSpeech,
      normalizedSpeech: normalized,
    );
  }

  /// Hàm tiện ích tương thích ngược trực tiếp trả về int?
  /// Trả về null khi trẻ từ chối trả lời (isUnknown) hoặc khi không tìm thấy số hợp lệ.
  static int? extractNumber(String rawSpeech) {
    return extract(rawSpeech).value;
  }

  static int? _parseTokens(List<String> words) {
    // Trường hợp 1 từ: "năm" -> 5, "mười" -> 10, "không" -> 0, "trăm" -> 100, "nghìn" -> 1000
    if (words.length == 1) {
      final w = words.first;
      if (w == 'mười' || w == 'chục') return 10;
      if (w == 'trăm') return 100;
      if (w == 'nghìn' || w == 'ngàn') return 1000;
      if (_unitWords.containsKey(w)) return _unitWords[w];
      return null;
    }

    // Trường hợp hàng nghìn / ngàn: ví dụ "một nghìn", "hai ngàn năm trăm"
    if (words.contains('nghìn') || words.contains('ngàn')) {
      final nghinWord = words.contains('nghìn') ? 'nghìn' : 'ngàn';
      final nghinIndex = words.indexOf(nghinWord);
      int thousands = 1;
      if (nghinIndex > 0) {
        thousands = _unitWords[words[nghinIndex - 1]] ?? 1;
      }

      final remainderWords = words.sublist(nghinIndex + 1);
      if (remainderWords.isEmpty) {
        return thousands * 1000;
      }

      final remValue = _parseTokens(remainderWords);
      if (remValue != null) {
        return thousands * 1000 + remValue;
      }
      return thousands * 1000;
    }

    // Trường hợp hàng trăm: ví dụ "một trăm", "một trăm linh năm", "hai trăm hai mươi mốt"
    if (words.contains('trăm')) {
      final tramIndex = words.indexOf('trăm');
      int hundreds = 1;
      if (tramIndex > 0) {
        hundreds = _unitWords[words[tramIndex - 1]] ?? 1;
      }

      final remainderWords = words.sublist(tramIndex + 1);
      if (remainderWords.isEmpty) {
        return hundreds * 100;
      }

      // Xử lý "linh" hoặc "lẻ": ví dụ "linh năm" -> 5
      if (remainderWords.first == 'linh' || remainderWords.first == 'lẻ') {
        if (remainderWords.length > 1) {
          final unit = _unitWords[remainderWords[1]];
          if (unit != null) return hundreds * 100 + unit;
        }
        return hundreds * 100;
      }

      final remValue = _parseTokens(remainderWords);
      if (remValue != null) {
        return hundreds * 100 + remValue;
      }
      return hundreds * 100;
    }

    // Trường hợp 2 từ:
    // "mười một" -> 11, "mười lăm" -> 15
    // "hai mươi" -> 20, "hai mốt" -> 21, "ba lăm" -> 35, "hai nhăm" -> 25, "bốn tư" -> 44
    if (words.length == 2) {
      final w1 = words[0];
      final w2 = words[1];

      if (w1 == 'mười') {
        final unit = _unitWords[w2];
        if (unit != null) return 10 + unit;
      }

      final tens = _unitWords[w1];
      if (tens != null) {
        if (w2 == 'mươi' || w2 == 'chục') return tens * 10;
        final unit = _unitWords[w2];
        if (unit != null) return tens * 10 + unit;
      }
      return null;
    }

    // Trường hợp 3 từ:
    // "hai mươi mốt" -> 21, "ba mươi lăm" -> 35, "bốn mươi tư" -> 44
    if (words.length == 3) {
      final w1 = words[0];
      final w2 = words[1];
      final w3 = words[2];

      if (w2 == 'mươi' || w2 == 'chục') {
        final tens = _unitWords[w1];
        final unit = _unitWords[w3];
        if (tens != null && unit != null) {
          return tens * 10 + unit;
        }
      }
    }

    return null;
  }
}
