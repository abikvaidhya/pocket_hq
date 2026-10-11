/// Rule-based natural-language parser for reminder / timer / alarm phrases.
/// No ML required — deterministic and fully offline.
class ParsedReminder {
  final String label;
  final DateTime triggerAt;
  final String kind; // reminder | timer | alarm
  final String sourceText;

  const ParsedReminder({
    required this.label,
    required this.triggerAt,
    required this.kind,
    required this.sourceText,
  });
}

class ReminderParseException implements Exception {
  final String message;
  ReminderParseException(this.message);
  @override
  String toString() => message;
}

class ReminderParser {
  ReminderParser._();

  static const _weekdays = {
    'monday': DateTime.monday,
    'mon': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'tue': DateTime.tuesday,
    'tues': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'wed': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'thu': DateTime.thursday,
    'thur': DateTime.thursday,
    'thurs': DateTime.thursday,
    'friday': DateTime.friday,
    'fri': DateTime.friday,
    'saturday': DateTime.saturday,
    'sat': DateTime.saturday,
    'sunday': DateTime.sunday,
    'sun': DateTime.sunday,
  };

  /// Parse spoken or typed text into a [ParsedReminder].
  /// Throws [ReminderParseException] if no usable time is found.
  static ParsedReminder parse(String raw, {DateTime? now}) {
    final source = raw.trim();
    if (source.isEmpty) {
      throw ReminderParseException('Say or type something with a time.');
    }

    final lower = source.toLowerCase().replaceAll(RegExp(r'[.,!?]+'), ' ');
    final cleaned = lower.replaceAll(RegExp(r'\s+'), ' ').trim();
    final clock = now ?? DateTime.now();

    final kind = _detectKind(cleaned);
    DateTime? trigger = _parseRelative(cleaned, clock) ??
        _parseAbsoluteClock(cleaned, clock) ??
        _parseWeekdayClock(cleaned, clock) ??
        _parseNamedDayClock(cleaned, clock);

    if (trigger == null) {
      throw ReminderParseException(
        'Couldn’t find a time. Try “in 15 minutes” or “tomorrow at 6 AM”.',
      );
    }

    // Past absolute times for “today” → next day (except pure relative which is always future)
    if (trigger.isBefore(clock) && !_isRelativePhrase(cleaned)) {
      // If only a clock time was given and it’s past, assume tomorrow
      if (_looksLikeTodayClockOnly(cleaned)) {
        trigger = trigger.add(const Duration(days: 1));
      } else if (trigger.isBefore(clock)) {
        // weekday already computed as next occurrence; if still past, add a week
        trigger = trigger.add(const Duration(days: 7));
      }
    }

    final label = _extractLabel(cleaned, kind);

    return ParsedReminder(
      label: label,
      triggerAt: trigger,
      kind: kind,
      sourceText: source,
    );
  }

  static bool _isRelativePhrase(String s) =>
      RegExp(r'\bin\s+\d|\bfor\s+\d|\btimer\b|\bafter\s+\d').hasMatch(s);

  static bool _looksLikeTodayClockOnly(String s) {
    final hasDayWord = RegExp(
      r'\b(today|tomorrow|tonight|monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)\b',
    ).hasMatch(s);
    return !hasDayWord && !_isRelativePhrase(s);
  }

  static String _detectKind(String s) {
    if (RegExp(r'\b(timer|countdown)\b').hasMatch(s)) return 'timer';
    if (RegExp(r'\b(alarm|wake\s*up|wake me)\b').hasMatch(s)) return 'alarm';
    return 'reminder';
  }

  /// "in 15 minutes", "in 2 hours", "timer of 40 minutes", "for 30 mins"
  static DateTime? _parseRelative(String s, DateTime now) {
    final patterns = [
      RegExp(
        r'(?:in|for|after|of)\s+(\d+)\s*(seconds?|secs?|minutes?|mins?|min|hours?|hrs?|hr|days?|day)\b',
      ),
      RegExp(
        r'(\d+)\s*(seconds?|secs?|minutes?|mins?|min|hours?|hrs?|hr|days?|day)\s*(?:timer|from now|later)?\b',
      ),
    ];

    for (final re in patterns) {
      final m = re.firstMatch(s);
      if (m == null) continue;
      final n = int.tryParse(m.group(1)!);
      if (n == null || n <= 0) continue;
      final unit = m.group(2)!;
      final duration = _duration(n, unit);
      if (duration != null) return now.add(duration);
    }
    return null;
  }

  static Duration? _duration(int n, String unit) {
    if (unit.startsWith('sec')) return Duration(seconds: n);
    if (unit.startsWith('min')) return Duration(minutes: n);
    if (unit.startsWith('hour') || unit.startsWith('hr')) {
      return Duration(hours: n);
    }
    if (unit.startsWith('day')) return Duration(days: n);
    return null;
  }

  /// "at 8pm", "at 11:30 am", "8 PM", "18:00"
  static DateTime? _parseAbsoluteClock(String s, DateTime now) {
    final time = _matchTime(s);
    if (time == null) return null;

    // Prefer explicit today/tonight/tomorrow handled elsewhere; here base = today
    var day = DateTime(now.year, now.month, now.day);
    if (s.contains('tonight')) {
      // evening default if hour < 12 and no am/pm? keep parsed hour
    }
    if (s.contains('tomorrow')) {
      day = day.add(const Duration(days: 1));
    }

    return DateTime(day.year, day.month, day.day, time.$1, time.$2);
  }

  /// "saturday at 11 am", "coming friday 6pm"
  static DateTime? _parseWeekdayClock(String s, DateTime now) {
    int? weekday;
    for (final e in _weekdays.entries) {
      if (RegExp('\\b${e.key}\\b').hasMatch(s)) {
        weekday = e.value;
        break;
      }
    }
    if (weekday == null) return null;

    final time = _matchTime(s) ?? (9, 0); // default 9:00 if only weekday
    var day = DateTime(now.year, now.month, now.day);
    var add = (weekday - day.weekday + 7) % 7;
    if (add == 0) {
      // same weekday — if time already passed, next week
      final candidate =
          DateTime(day.year, day.month, day.day, time.$1, time.$2);
      if (candidate.isBefore(now) || candidate.isAtSameMomentAs(now)) {
        add = 7;
      }
    }
    day = day.add(Duration(days: add));
    return DateTime(day.year, day.month, day.day, time.$1, time.$2);
  }

  static DateTime? _parseNamedDayClock(String s, DateTime now) {
    if (s.contains('tomorrow')) {
      final time = _matchTime(s) ?? (9, 0);
      final day = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1));
      return DateTime(day.year, day.month, day.day, time.$1, time.$2);
    }
    if (s.contains('today') || s.contains('tonight')) {
      final time = _matchTime(s);
      if (time == null) return null;
      final day = DateTime(now.year, now.month, now.day);
      return DateTime(day.year, day.month, day.day, time.$1, time.$2);
    }
    return null;
  }

  /// Returns (hour24, minute).
  static (int, int)? _matchTime(String s) {
    // 11:30 am / 11.30pm / 8pm / 08:00
    final withMeridiem = RegExp(
      r'\b(\d{1,2})(?:[:.](\d{2}))?\s*(a\.?m\.?|p\.?m\.?)\b',
    ).firstMatch(s);
    if (withMeridiem != null) {
      var h = int.parse(withMeridiem.group(1)!);
      final m = int.parse(withMeridiem.group(2) ?? '0');
      final ap = withMeridiem.group(3)!.toLowerCase().replaceAll('.', '');
      if (ap.startsWith('p') && h < 12) h += 12;
      if (ap.startsWith('a') && h == 12) h = 0;
      if (h > 23 || m > 59) return null;
      return (h, m);
    }

    final military = RegExp(r'\b([01]?\d|2[0-3])[:.]([0-5]\d)\b').firstMatch(s);
    if (military != null) {
      return (int.parse(military.group(1)!), int.parse(military.group(2)!));
    }

    // bare hour with context words: "at 8", "for 8"
    final bare = RegExp(r'\b(?:at|@)\s+(\d{1,2})\b').firstMatch(s);
    if (bare != null) {
      var h = int.parse(bare.group(1)!);
      if (h < 0 || h > 23) return null;
      // Heuristic: if 1–7 without am/pm and not "tonight", treat as PM for common speech
      // Safer: leave as 24h if 0-23; for 1-12 without meridiem keep as-is (morning)
      return (h, 0);
    }

    return null;
  }

  static String _extractLabel(String s, String kind) {
    var t = s;

    // Strip command prefixes
    t = t.replaceFirst(
      RegExp(
        r'^(please\s+)?(can you\s+)?(set\s+(a\s+)?|create\s+(a\s+)?|make\s+(a\s+)?|add\s+(a\s+)?)?(reminder|alarm|timer|alert)\s*(for|to|of)?\s*',
      ),
      '',
    );
    t = t.replaceFirst(RegExp(r'^(remind\s+me\s+(to|about)\s+)'), '');
    t = t.replaceFirst(RegExp(r'^(wake\s+me\s+(up\s+)?)'), '');

    // Strip time phrases
    t = t.replaceAll(
      RegExp(
        r'\b(in|for|after|of)\s+\d+\s*(seconds?|secs?|minutes?|mins?|min|hours?|hrs?|hr|days?|day)\b',
      ),
      ' ',
    );
    t = t.replaceAll(
      RegExp(
        r'\b(today|tonight|tomorrow|coming|next)?\s*(monday|tuesday|wednesday|thursday|friday|saturday|sunday|mon|tue|wed|thu|fri|sat|sun)?\s*(at|@)?\s*\d{1,2}(?:[:.]\d{2})?\s*(a\.?m\.?|p\.?m\.?)?\b',
      ),
      ' ',
    );
    t = t.replaceAll(
      RegExp(r'\b(at|@)\s+\d{1,2}(?:[:.]\d{2})?\s*(a\.?m\.?|p\.?m\.?)?\b'),
      ' ',
    );
    t = t.replaceAll(RegExp(r'\b(timer|alarm|reminder|countdown)\b'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceAll(RegExp(r'^(to|for|about)\s+'), '');

    if (t.isEmpty) {
      switch (kind) {
        case 'timer':
          return 'Timer';
        case 'alarm':
          return 'Alarm';
        default:
          return 'Reminder';
      }
    }

    // Title case first letter
    return t[0].toUpperCase() + t.substring(1);
  }
}
