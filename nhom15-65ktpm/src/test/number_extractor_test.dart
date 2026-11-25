import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/features/4_ai_voice_tutor/domain/usecases/vietnamese_number_extractor.dart';

void main() {
  group('Vietnamese Number Extractor Tests (Mục 7.7 - Nút Micro AI)', () {
    test('TC_NLP_01: Trích xuất số đơn lẻ và số dạng chữ số trực tiếp', () {
      expect(VietnameseNumberExtractor.extractNumber('năm'), 5);
      expect(VietnameseNumberExtractor.extractNumber('số 7'), 7);
      expect(VietnameseNumberExtractor.extractNumber('15'), 15);
      expect(VietnameseNumberExtractor.extractNumber('bằng 8'), 8);
      expect(VietnameseNumberExtractor.extractNumber('kết quả là 25'), 25);
    });

    test('TC_NLP_02: Trích xuất câu nói tự nhiên kèm từ đệm & dạ thưa của trẻ', () {
      // Yêu cầu bài kiểm thử đặc tả mục 7.7
      expect(
        VietnameseNumberExtractor.extractNumber('dạ kết quả là bằng mười lăm'),
        15,
      );
      expect(
        VietnameseNumberExtractor.extractNumber('thưa cô bằng hai mươi bốn'),
        24,
      );
      expect(
        VietnameseNumberExtractor.extractNumber('dạ thưa cô kết quả bằng mười lăm ạ'),
        15,
      );
      expect(
        VietnameseNumberExtractor.extractNumber('dạ con tính ra kết quả là mười ạ'),
        10,
      );
      expect(
        VietnameseNumberExtractor.extractNumber('thưa thầy đáp án là chín ạ'),
        9,
      );
      expect(
        VietnameseNumberExtractor.extractNumber('cho con hỏi đáp án là bằng ba'),
        3,
      );
    });

    test('TC_NLP_03: Trích xuất các số hàng chục và phương ngữ vùng miền', () {
      // Các biến thể vùng miền được đặc tả mục 7.7
      expect(VietnameseNumberExtractor.extractNumber('hai mươi mốt'), 21);
      expect(VietnameseNumberExtractor.extractNumber('ba mươi lăm'), 35);
      expect(VietnameseNumberExtractor.extractNumber('hai nhăm'), 25);
      expect(VietnameseNumberExtractor.extractNumber('mười lăm'), 15);
      expect(VietnameseNumberExtractor.extractNumber('mười một'), 11);
      expect(VietnameseNumberExtractor.extractNumber('hai mươi'), 20);
      expect(VietnameseNumberExtractor.extractNumber('hăm mốt'), 21);
      expect(VietnameseNumberExtractor.extractNumber('hăm nhăm'), 25);
      expect(VietnameseNumberExtractor.extractNumber('bốn mươi tư'), 44);
      expect(VietnameseNumberExtractor.extractNumber('ba lăm'), 35);
    });

    test('TC_NLP_04: Trích xuất số âm (âm năm, -5, trừ năm)', () {
      expect(VietnameseNumberExtractor.extractNumber('âm năm'), -5);
      expect(VietnameseNumberExtractor.extractNumber('-5'), -5);
      expect(VietnameseNumberExtractor.extractNumber('trừ năm'), -5);
      expect(VietnameseNumberExtractor.extractNumber('kết quả là âm mười lăm'), -15);
      expect(VietnameseNumberExtractor.extractNumber('dạ bằng -25 ạ'), -25);
    });

    test('TC_NLP_05: Xử lý câu từ chối / không biết -> trả về null và kích hoạt gợi ý (hint)', () {
      // Hàm extractNumber trả về null
      expect(VietnameseNumberExtractor.extractNumber('dạ con không biết'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('con không biết ạ'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('khó quá con chịu'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('bỏ qua bài này'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('con không làm được'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('chịu'), isNull);

      // Chi tiết ExtractionResult.isUnknown == true
      final res1 = VietnameseNumberExtractor.extract('dạ con không biết');
      expect(res1.isUnknown, isTrue);
      expect(res1.value, isNull);

      final res2 = VietnameseNumberExtractor.extract('con không biết ạ');
      expect(res2.isUnknown, isTrue);
      expect(res2.value, isNull);

      final res3 = VietnameseNumberExtractor.extract('khó quá con chịu');
      expect(res3.isUnknown, isTrue);
      expect(res3.value, isNull);
    });

    test('TC_NLP_06: Xử lý chuỗi rác / không có số hợp lệ -> trả về null (unrecognized)', () {
      expect(VietnameseNumberExtractor.extractNumber('con thích ăn kem'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('xin chào cô giáo'), isNull);
      expect(VietnameseNumberExtractor.extractNumber('dạ con chào cô ạ'), isNull);
      expect(VietnameseNumberExtractor.extractNumber(''), isNull);

      final resGarbage = VietnameseNumberExtractor.extract('con thích ăn kem');
      expect(resGarbage.isNumber, isFalse);
      expect(resGarbage.isUnknown, isFalse);
      expect(resGarbage.isUnrecognized, isTrue);
      expect(resGarbage.value, isNull);

      final resEmpty = VietnameseNumberExtractor.extract('   ');
      expect(resEmpty.isEmpty, isTrue);
      expect(resEmpty.value, isNull);
    });

    test('TC_NLP_07: Trích xuất số hàng trăm, hàng nghìn và linh/lẻ', () {
      expect(VietnameseNumberExtractor.extractNumber('một trăm linh năm'), 105);
      expect(VietnameseNumberExtractor.extractNumber('một trăm lẻ bảy'), 107);
      expect(VietnameseNumberExtractor.extractNumber('hai trăm hai mươi mốt'), 221);
      expect(VietnameseNumberExtractor.extractNumber('năm trăm'), 500);
      expect(VietnameseNumberExtractor.extractNumber('một nghìn'), 1000);
      expect(VietnameseNumberExtractor.extractNumber('hai ngàn năm trăm'), 2500);
    });
  });
}
