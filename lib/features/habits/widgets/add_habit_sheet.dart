import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../../../data/models/habit.dart';
import '../../../providers/habits_provider.dart';

class AddHabitSheet extends ConsumerStatefulWidget {
  final Habit? existing;
  const AddHabitSheet({super.key, this.existing});

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  final _titleCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _colorValue = 0xFF5B6CFF;
  int? _reminderHour;
  int? _reminderMinute;
  bool _reminderEnabled = false;

  static const _palette = [
    0xFF5B6CFF,
    0xFF00C853,
    0xFFFF6D00,
    0xFFE91E63,
    0xFF00BCD4,
    0xFF9C27B0,
    0xFFFFC107,
    0xFF607D8B,
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final h = widget.existing;
    if (h != null) {
      _titleCtrl.text = h.title;
      _colorValue = h.colorValue;
      _reminderHour = h.reminderHour;
      _reminderMinute = h.reminderMinute;
      _reminderEnabled = h.reminderHour != null;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEditing ? 'Edit habit' : 'New habit',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleCtrl,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Morning stretch',
                prefixIcon: Icon(Iconsax.edit_2),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a name';
                if (v.trim().length < 2) return 'Too short';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Color',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _palette.map((c) {
                final selected = c == _colorValue;
                return GestureDetector(
                  onTap: () => setState(() => _colorValue = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
                          : null,
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Color(c).withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Iconsax.notification),
              title: const Text('Daily reminder'),
              subtitle: _reminderEnabled && _reminderHour != null
                  ? Text(
                      '${_reminderHour!.toString().padLeft(2, '0')}:'
                      '${_reminderMinute!.toString().padLeft(2, '0')}',
                    )
                  : const Text('Off'),
              value: _reminderEnabled,
              onChanged: (v) async {
                if (v) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: _reminderHour ?? 8,
                      minute: _reminderMinute ?? 0,
                    ),
                  );
                  if (time != null) {
                    setState(() {
                      _reminderEnabled = true;
                      _reminderHour = time.hour;
                      _reminderMinute = time.minute;
                    });
                  }
                } else {
                  setState(() {
                    _reminderEnabled = false;
                    _reminderHour = null;
                    _reminderMinute = null;
                  });
                }
              },
            ),
            if (_reminderEnabled)
              TextButton.icon(
                onPressed: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: _reminderHour ?? 8,
                      minute: _reminderMinute ?? 0,
                    ),
                  );
                  if (time != null) {
                    setState(() {
                      _reminderHour = time.hour;
                      _reminderMinute = time.minute;
                    });
                  }
                },
                icon: const Icon(Iconsax.clock, size: 18),
                label: const Text('Change time'),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Save changes' : 'Create habit'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleCtrl.text.trim();
    final notifier = ref.read(habitsProvider.notifier);

    if (_isEditing) {
      // final updated = widget.existing!.copyWith(
      //   title: title,
      //   colorValue: _colorValue,
      //   reminderHour: _reminderEnabled ? _reminderHour : null,
      //   reminderMinute: _reminderEnabled ? _reminderMinute : null,
      // );
      // Preserve streak fields by mutating the original object
      final original = widget.existing!;
      original.title = title;
      original.colorValue = _colorValue;
      original.reminderHour = _reminderEnabled ? _reminderHour : null;
      original.reminderMinute = _reminderEnabled ? _reminderMinute : null;
      await notifier.update(original);
    } else {
      final habit = Habit(
        title: title,
        colorValue: _colorValue,
        reminderHour: _reminderEnabled ? _reminderHour : null,
        reminderMinute: _reminderEnabled ? _reminderMinute : null,
      );
      await notifier.add(habit);
    }

    if (mounted) Navigator.of(context).pop();
  }
}
