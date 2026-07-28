import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chat_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../services/voice_service.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/itinerary_card.dart';
import '../../widgets/voice_mic_button.dart';
import '../search/itinerary_detail_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _voice = VoiceService();
  bool _voiceReady = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _voice.init().then((ready) => setState(() => _voiceReady = ready));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText([String? textOverride]) async {
    final text = textOverride ?? _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    final chat = context.read<ChatProvider>();
    await chat.send(text);
    if (!mounted) return;
    _scrollToBottom();

    final femaleVoice =
        context.read<PreferencesProvider>().preferences.preferredVoiceIsFemale;
    final reply = chat.messages.last.text;
    unawaited(_voice.speak(reply, useFemaleVoice: femaleVoice));
  }

  Future<void> _toggleListening() async {
    if (!_voiceReady) return;
    if (_isListening) {
      await _voice.stopListening();
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    await _voice.startListening(
      onResult: (text, isFinal) {
        _controller.text = text;
        if (isFinal) {
          setState(() => _isListening = false);
          final chat = context.read<ChatProvider>();
          _controller.clear();
          chat.send(text, wasSpoken: true).then((_) {
            if (!mounted) return;
            _scrollToBottom();
            final femaleVoice = context
                .read<PreferencesProvider>()
                .preferences
                .preferredVoiceIsFemale;
            unawaited(_voice.speak(chat.messages.last.text, useFemaleVoice: femaleVoice));
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('KI-Reiseberater')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                for (final message in chat.messages) ChatBubble(message: message),
                if (chat.isThinking)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'denkt nach...',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (chat.lastResults != null)
                  for (final itinerary in chat.lastResults!.take(3))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ItineraryCard(
                        itinerary: itinerary,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ItineraryDetailScreen(itinerary: itinerary),
                          ),
                        ),
                      ),
                    ),
                if (chat.messages.length <= 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final suggestion in const [
                          'Nach Casablanca',
                          'Nach Fès',
                          'Günstigste Option',
                          'Ich reise mit meiner Familie',
                        ])
                          ActionChip(
                            label: Text(suggestion),
                            onPressed: () => _sendText(suggestion),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                      decoration: const InputDecoration(
                        hintText: 'Bghit arkhass vol... / Schreib mir...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  VoiceMicButton(
                    isListening: _isListening,
                    onPressed: _toggleListening,
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sendText,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

