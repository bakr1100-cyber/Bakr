import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/chat_provider.dart';
import '../../providers/home_navigation_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../services/voice_service.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/itinerary_card.dart';
import '../../widgets/responsive_body.dart';
import '../../widgets/typing_indicator.dart';
import '../../widgets/voice_mic_button.dart';
import '../search/itinerary_detail_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.autoStartListening = false});

  /// Starts listening as soon as speech-to-text is ready, without waiting
  /// for the shared [HomeNavigationProvider] flag - used when this screen is
  /// pushed directly (e.g. right after picking a language onboarding),
  /// rather than being the always-mounted tab instance inside [HomeScreen].
  final bool autoStartListening;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _voice = VoiceService();
  bool _voiceReady = false;
  bool _isListening = false;
  late final HomeNavigationProvider _navigation;

  /// Set when the user manually taps send while a voice recording is still
  /// active. Without this, stopping the recording still delivers one last
  /// `onResult(isFinal: true)` callback for whatever was already sent
  /// manually, which would otherwise send the exact same message a second
  /// time - a race that was actually observed sending duplicate messages.
  bool _suppressNextAutoSend = false;

  @override
  void initState() {
    super.initState();
    _voice.init().then((ready) => setState(() => _voiceReady = ready));
    _navigation = context.read<HomeNavigationProvider>();
    _navigation.addListener(_onNavigationChanged);
    // Covers the case where the flag was already set before this listener
    // was attached (e.g. the very first frame the assistant tab exists).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onNavigationChanged();
      if (widget.autoStartListening) _startVoiceAsSoonAsReady();
    });
  }

  void _onNavigationChanged() {
    if (!_navigation.pendingVoiceStart) return;
    _navigation.consumePendingVoiceStart();
    _startVoiceAsSoonAsReady();
  }

  /// STT initialization is async, so if the user tapped the landing page's
  /// voice card before it finished, wait briefly instead of silently
  /// dropping the request.
  Future<void> _startVoiceAsSoonAsReady() async {
    var attempts = 0;
    while (!_voiceReady && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    if (!mounted || _isListening || !_voiceReady) return;
    _toggleListening();
  }

  @override
  void dispose() {
    _navigation.removeListener(_onNavigationChanged);
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
    // Must happen synchronously, before any `await` below, or the browser
    // no longer considers the eventual speak() call part of this tap and
    // silently blocks it (see VoiceService.unlockSpeechForThisGesture).
    _voice.unlockSpeechForThisGesture();
    if (_isListening) {
      // Stopping still delivers one last isFinal result - suppress it so
      // this manual send isn't immediately duplicated by the voice path.
      _suppressNextAutoSend = true;
      await _voice.stopListening();
      if (!mounted) return;
      setState(() => _isListening = false);
    }
    _controller.clear();
    final chat = context.read<ChatProvider>();
    final language = context.read<LocaleProvider>().language;
    await chat.send(text, language: language);
    if (!mounted) return;
    _scrollToBottom();

    final femaleVoice =
        context.read<PreferencesProvider>().preferences.preferredVoiceIsFemale;
    final reply = chat.messages.last.text;
    unawaited(_voice.speak(reply, useFemaleVoice: femaleVoice, locale: language.speechLocale));
  }

  Future<void> _toggleListening() async {
    if (!_voiceReady) return;
    // Same reasoning as in _sendText: unlock synchronously now, so the
    // reply spoken later (after listening + the network round-trip) isn't
    // silently blocked by the browser.
    _voice.unlockSpeechForThisGesture();
    if (_isListening) {
      await _voice.stopListening();
      setState(() => _isListening = false);
      return;
    }
    final language = context.read<LocaleProvider>().language;
    // Guarantees a clean slate: without this, leftover text from the
    // previous message (already sent) stayed in the field and got
    // silently concatenated with this session's recognition result the
    // moment the first onResult callback fired.
    _controller.clear();
    setState(() => _isListening = true);
    await _voice.startListening(
      localeId: language.speechLocale,
      onResult: (text, isFinal) {
        _controller.text = text;
        if (isFinal) {
          setState(() => _isListening = false);
          if (_suppressNextAutoSend) {
            _suppressNextAutoSend = false;
            return;
          }
          final chat = context.read<ChatProvider>();
          _controller.clear();
          chat.send(text, wasSpoken: true, language: language).then((_) {
            if (!mounted) return;
            _scrollToBottom();
            final femaleVoice = context
                .read<PreferencesProvider>()
                .preferences
                .preferredVoiceIsFemale;
            unawaited(_voice.speak(
              chat.messages.last.text,
              useFemaleVoice: femaleVoice,
              locale: language.speechLocale,
            ));
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final t = AppLocalizations.of(context).t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('aiChatTitle')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 6),
                Text(
                  t('aiChatSubtitle'),
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ResponsiveBody(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  for (final message in chat.messages) ChatBubble(message: message),
                  if (chat.isThinking)
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: TypingIndicator(),
                    ),
                  if (chat.lastResults != null)
                    for (var i = 0; i < chat.lastResults!.take(3).length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: ItineraryCard(
                          itinerary: chat.lastResults![i],
                          isBestValue: i == 0,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ItineraryDetailScreen(itinerary: chat.lastResults![i]),
                            ),
                          ),
                        ),
                      ),
                  if (chat.messages.length <= 1)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final suggestion in [
                            t('suggestionCasablanca'),
                            t('suggestionFes'),
                            t('suggestionCheapest'),
                            t('suggestionFamily'),
                          ])
                            ActionChip(
                              avatar: const Icon(Icons.bolt_rounded, size: 16),
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
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendText(),
                          decoration: const InputDecoration(
                            hintText: 'Bghit arkhass vol… / Schreib mir…',
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                      VoiceMicButton(
                        isListening: _isListening,
                        onPressed: _toggleListening,
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        onPressed: _sendText,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

