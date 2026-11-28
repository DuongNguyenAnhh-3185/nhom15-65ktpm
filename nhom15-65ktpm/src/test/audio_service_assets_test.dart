import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soroban_kids_app/core/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('feedback sound assets are bundled at the configured paths', () async {
    final applause = await rootBundle.load(AudioService.successSoundAssetPath);
    final gentleWah =
        await rootBundle.load(AudioService.incorrectSoundAssetPath);

    expect(applause.lengthInBytes, greaterThan(0));
    expect(gentleWah.lengthInBytes, greaterThan(0));
  });
}
