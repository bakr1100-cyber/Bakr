import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/services/voice_clients.dart';

enum VoiceStatus { idle, listening, speaking }

class VoiceController extends Notifier<VoiceStatus> {
  @override
  VoiceStatus build() => VoiceStatus.idle;

  Future<String> listen() async {
    state = VoiceStatus.listening;
    try {
      return await ref.read(sttClientProvider).listen();
    } finally {
      state = VoiceStatus.idle;
    }
  }

  Future<void> speak(String text, {VoiceGender voice = VoiceGender.female}) async {
    state = VoiceStatus.speaking;
    try {
      await ref.read(ttsClientProvider).speak(text, voice: voice);
    } finally {
      state = VoiceStatus.idle;
    }
  }
}

final voiceControllerProvider =
    NotifierProvider<VoiceController, VoiceStatus>(VoiceController.new);
