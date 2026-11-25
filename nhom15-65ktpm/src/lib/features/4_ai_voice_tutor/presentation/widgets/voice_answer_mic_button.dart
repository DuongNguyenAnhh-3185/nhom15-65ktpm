import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/constants/app_colors.dart';
import '../../domain/usecases/vietnamese_number_extractor.dart';

enum VoiceMicState {
  idle,
  listening,
  processing,
  hintShown,
  unavailable,
  error,
}

typedef AiMicState = VoiceMicState;

/// Nút Micro AI nhận diện giọng nói tiếng Việt (Mục 7.7)
/// Hỗ trợ các trạng thái: idle, listening, processing, hintShown, unavailable, error.
/// Nhận diện giọng nói tiếng Việt (vi_VN) qua SpeechToText, bóc tách số qua VietnameseNumberExtractor,
/// hỗ trợ tự động kích hoạt gợi ý (hint) khi trẻ nói từ chối ("con không biết", "chịu", "khó quá"...).
class VoiceAnswerMicButton extends StatefulWidget {
  final Function(int number, String rawSpeech) onAnswerDetected;
  final Function(String speechOrReason)? onHintRequested;
  final Function(String statusMessage)? onStatusChanged;
  final Function(String errorMessage)? onError;

  const VoiceAnswerMicButton({
    super.key,
    required this.onAnswerDetected,
    this.onHintRequested,
    this.onStatusChanged,
    this.onError,
  });

  @override
  State<VoiceAnswerMicButton> createState() => _VoiceAnswerMicButtonState();
}

/// Alias cho VoiceAnswerMicButton theo đặc tả 7.7
typedef AiMicButton = VoiceAnswerMicButton;

class _VoiceAnswerMicButtonState extends State<VoiceAnswerMicButton>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  VoiceMicState _state = VoiceMicState.idle;
  String _recognizedWords = '';
  String _lastTranscript = '';
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _setState(VoiceMicState newState) {
    if (mounted) {
      setState(() => _state = newState);
    }
  }

  Future<void> _toggleListening() async {
    if (_state == VoiceMicState.listening) {
      await _speech.stop();
      _setState(VoiceMicState.idle);
      widget.onStatusChanged?.call('Đã dừng nghe.');
      return;
    }

    bool available = false;
    try {
      available = await _speech.initialize(
        onError: (val) {
          if (!mounted) return;
          _setState(VoiceMicState.error);
          widget.onStatusChanged?.call('Lỗi nhận diện giọng nói: ${val.errorMsg}');
          widget.onError?.call(val.errorMsg);
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && _state == VoiceMicState.error) {
              _setState(VoiceMicState.idle);
            }
          });
        },
        onStatus: (val) {
          if (!mounted) return;
          if (val == 'done' || val == 'notListening') {
            if (_state == VoiceMicState.listening) {
              _setState(VoiceMicState.idle);
            }
          }
        },
      );
    } catch (_) {
      available = false;
    }

    if (!mounted) return;

    if (available) {
      _setState(VoiceMicState.listening);
      _recognizedWords = '';
      widget.onStatusChanged?.call('Đang lắng nghe bé nói... Hãy đọc to đáp án nhé!');

      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(localeId: 'vi_VN'),
        onResult: (result) {
          if (!mounted) return;
          _recognizedWords = result.recognizedWords;
          setState(() {
            _lastTranscript = _recognizedWords;
          });
          widget.onStatusChanged?.call('Bé vừa nói: "$_recognizedWords"');

          final extraction = VietnameseNumberExtractor.extract(_recognizedWords);

          // 1. Nếu bé nói "con không biết", "chịu", "khó quá" -> Kích hoạt gợi ý (hint)
          if (extraction.isUnknown) {
            _speech.stop();
            _setState(VoiceMicState.hintShown);
            widget.onStatusChanged?.call('Đừng lo bé nhé! Xem gợi ý thị phạm nào! 💡');
            widget.onHintRequested?.call(_recognizedWords);
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _state == VoiceMicState.hintShown) {
                _setState(VoiceMicState.idle);
              }
            });
            return;
          }

          // 2. Nếu trích xuất được số đáp án hợp lệ
          if (extraction.isNumber && extraction.value != null) {
            _speech.stop();
            _setState(VoiceMicState.processing);
            widget.onStatusChanged?.call('Đã nhận diện: ${extraction.value}');

            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                _setState(VoiceMicState.idle);
                widget.onAnswerDetected(extraction.value!, _recognizedWords);
              }
            });
          }
        },
      );
    } else {
      // Nếu thiết bị không hỗ trợ Speech-to-Text hoặc chưa cấp quyền Micro
      _setState(VoiceMicState.unavailable);
      _showPermissionOrUnavailableDialog();
    }
  }

  void _showPermissionOrUnavailableDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.mic_off_rounded, color: AppColors.warning, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cần quyền Microphone',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thiết bị chưa cấp quyền Microphone hoặc không hỗ trợ nhận diện giọng nói trực tiếp.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 10),
              Text(
                '💡 Bé hoặc ba mẹ hãy bật quyền Micro trong Cài đặt thiết bị, hoặc bấm "Thử mô phỏng phát ngôn" để kiểm tra tính năng NLP bóc tách số nhé!',
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _setState(VoiceMicState.idle);
              },
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(dialogCtx);
                _showVoiceSimulationDialog();
              },
              child: const Text('Thử mô phỏng AI'),
            ),
          ],
        );
      },
    );
  }

  void _showVoiceSimulationDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Text('🎙️ ', style: TextStyle(fontSize: 24)),
              Expanded(
                child: Text(
                  'Nói đáp án (Mô phỏng AI)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập câu phát ngôn tự nhiên của bé:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ví dụ: "dạ thưa cô bằng 15 ạ" hoặc "con không biết"',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Gợi ý câu mẫu nhanh:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textLight),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _quickPhraseChip(textController, 'dạ bằng năm'),
                  _quickPhraseChip(textController, 'hai mươi mốt'),
                  _quickPhraseChip(textController, 'hai nhăm'),
                  _quickPhraseChip(textController, 'mười lăm ạ'),
                  _quickPhraseChip(textController, 'con không biết'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _setState(VoiceMicState.idle);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final text = textController.text.trim();
                Navigator.pop(context);
                if (text.isEmpty) {
                  _setState(VoiceMicState.idle);
                  return;
                }

                setState(() {
                  _lastTranscript = text;
                });

                final extraction = VietnameseNumberExtractor.extract(text);

                if (extraction.isUnknown) {
                  _setState(VoiceMicState.hintShown);
                  widget.onHintRequested?.call(text);
                  Future.delayed(const Duration(seconds: 3), () {
                    if (mounted) _setState(VoiceMicState.idle);
                  });
                } else if (extraction.isNumber && extraction.value != null) {
                  _setState(VoiceMicState.processing);
                  Future.delayed(const Duration(milliseconds: 250), () {
                    if (mounted) {
                      _setState(VoiceMicState.idle);
                      widget.onAnswerDetected(extraction.value!, text);
                    }
                  });
                } else {
                  _setState(VoiceMicState.idle);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Không tìm thấy số trong câu: "$text"'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
  }

  Widget _quickPhraseChip(TextEditingController controller, String phrase) {
    return ActionChip(
      label: Text(phrase, style: const TextStyle(fontSize: 12)),
      onPressed: () => controller.text = phrase,
      backgroundColor: AppColors.cardBg,
    );
  }

  Color _getButtonColor() {
    switch (_state) {
      case VoiceMicState.listening:
        return AppColors.error;
      case VoiceMicState.processing:
        return AppColors.secondary;
      case VoiceMicState.hintShown:
        return AppColors.accentOrange;
      case VoiceMicState.unavailable:
        return Colors.blueGrey;
      case VoiceMicState.error:
        return Colors.red.shade700;
      case VoiceMicState.idle:
        return AppColors.primary;
    }
  }

  IconData _getIcon() {
    switch (_state) {
      case VoiceMicState.listening:
        return Icons.mic;
      case VoiceMicState.processing:
        return Icons.hourglass_top;
      case VoiceMicState.hintShown:
        return Icons.lightbulb;
      case VoiceMicState.unavailable:
        return Icons.mic_off_rounded;
      case VoiceMicState.error:
        return Icons.error_outline_rounded;
      case VoiceMicState.idle:
        return Icons.mic_none;
    }
  }

  String _getStatusText() {
    switch (_state) {
      case VoiceMicState.listening:
        return 'Đang nghe...';
      case VoiceMicState.hintShown:
        return '💡 Gợi ý!';
      case VoiceMicState.processing:
        return 'Đang xử lý...';
      case VoiceMicState.unavailable:
        return 'Chưa có quyền mic';
      case VoiceMicState.error:
        return 'Thử lại';
      case VoiceMicState.idle:
        return 'Bấm để nói';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getButtonColor();
    final icon = _getIcon();

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final scale = _state == VoiceMicState.listening
            ? 1.0 + (_animController.value * 0.14)
            : 1.0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(
                          alpha: _state == VoiceMicState.listening ? 0.45 : 0.25,
                        ),
                        blurRadius: _state == VoiceMicState.listening ? 22 : 10,
                        spreadRadius: _state == VoiceMicState.listening ? 5 : 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _getStatusText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (_lastTranscript.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxWidth: 240),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.record_voice_over_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Bé nói: "$_lastTranscript"',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
