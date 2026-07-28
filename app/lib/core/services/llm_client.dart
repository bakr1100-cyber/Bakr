import '../models/chat_message.dart';

/// Abstraction over the conversational AI backend (the `aiOrchestrator`
/// Cloud Function, which itself wraps Claude with tool-use). Swapping the
/// [MockLlmClient] below for a real callable-function-backed client is the
/// only change needed once an Anthropic API key is configured server-side.
abstract class LlmClient {
  Future<String> sendMessage(List<ChatMessage> history, String userText);
}

/// Keyword-driven mock that demonstrates multilingual/Darija understanding
/// (formal languages + Darija in Arabic script and Arabizi) without calling
/// a real LLM. Good enough to exercise the chat UI end-to-end; replace with
/// a real `aiOrchestrator` call once an LLM provider is wired up.
class MockLlmClient implements LlmClient {
  @override
  Future<String> sendMessage(
    List<ChatMessage> history,
    String userText,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final normalized = userText.toLowerCase();

    final mentionsBudget = normalized.contains('budget') ||
        normalized.contains('€') ||
        normalized.contains('euro');
    if (mentionsBudget) {
      return 'Verstanden, ich suche Optionen innerhalb deines Budgets und '
          'sage dir Bescheid, sobald ich etwas Passendes gefunden habe.';
    }

    // Darija (Arabizi) example from the product brief.
    if (normalized.contains('bghit') || normalized.contains('arkhass')) {
      return 'Fhemtek! Ghadi nqelleb 3la arkhass tarik ليك. '
          'Wach 3ndek chi tarikh mo3ayan?';
    }

    // Darija (Arabic script) example from the product brief.
    if (userText.contains('بغيت') || userText.contains('طيارة')) {
      return 'مزيان، غادي نقلب ليك على أرخص طيارة. شحال هو الميزانية ديالك؟';
    }

    if (normalized.contains('fès') ||
        normalized.contains('fes') ||
        normalized.contains('fez')) {
      return 'Nach Fès gibt es oft eine günstigere Route über Rabat plus '
          'Zug. Soll ich dir das im Detail zeigen?';
    }

    return 'Ich bin mir nicht ganz sicher, was du meinst. Kannst du mir '
        'Abflugort, Ziel und ungefähres Datum nennen?';
  }
}
