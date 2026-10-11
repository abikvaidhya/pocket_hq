/// Placeholder for on-device AI (TFLite / heuristics).
///
/// Suggested future features for Pocket HQ:
/// - Suggest cart items from purpose ("grocery" → milk, eggs…)
/// - Suggest reminder label from voice transcript
/// - Rank Today cards by predicted importance
/// - Habit completion likelihood / best reminder hour
///
/// Start with simple rule-based helpers; swap in TFLite models later
/// without changing call sites.
class AiAssistService {
  AiAssistService._();
  static final AiAssistService instance = AiAssistService._();

  /// Rule-based starter suggestions for a cart purpose.
  List<String> suggestCartItems(String purpose) {
    final p = purpose.toLowerCase();
    if (p.contains('groc') || p.contains('food') || p.contains('market')) {
      return ['Milk', 'Eggs', 'Bread', 'Fruit', 'Vegetables'];
    }
    if (p.contains('car') || p.contains('auto')) {
      return ['Oil', 'Filter', 'Wiper fluid', 'Bulbs'];
    }
    if (p.contains('home') || p.contains('house')) {
      return ['Cleaner', 'Trash bags', 'Paper towels'];
    }
    return const [];
  }
}
