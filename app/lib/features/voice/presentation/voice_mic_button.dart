import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/voice_controller.dart';

/// Mic button that drives the mocked STT flow and hands the resulting
/// transcript back to the caller (e.g. to send as a chat message). A real
/// implementation swaps [SttClient]/[TtsClient] for a cloud provider
/// without changing this widget.
class VoiceMicButton extends ConsumerWidget {
  const VoiceMicButton({super.key, required this.onTranscript});

  final ValueChanged<String> onTranscript;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(voiceControllerProvider);
    final isListening = status == VoiceStatus.listening;

    return IconButton.filledTonal(
      onPressed: () async {
        final transcript =
            await ref.read(voiceControllerProvider.notifier).listen();
        onTranscript(transcript);
      },
      icon: Icon(isListening ? Icons.mic : Icons.mic_none),
      tooltip: 'Sprachbefehl',
    );
  }
}
