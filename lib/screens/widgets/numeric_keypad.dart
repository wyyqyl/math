import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'game_tap_sound.dart';
import 'study_layout.dart';

class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
    required this.onSubmitPressed,
    required this.hasInput,
    this.rowHeight = 54,
    this.enabled = true,
    this.soundEnabled = false,
  });

  final ValueChanged<String> onNumberPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onSubmitPressed;
  final bool hasInput;
  final double rowHeight;
  final bool enabled;
  final bool soundEnabled;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (!enabled || event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        final character = event.character;
        if (character != null && RegExp(r'^[0-9]$').hasMatch(character)) {
          onNumberPressed(character);
        } else if (key == LogicalKeyboardKey.backspace ||
            key == LogicalKeyboardKey.delete) {
          onDeletePressed();
        } else if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) {
          onSubmitPressed();
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in ['123', '456', '789', '⌫0✓']) ...[
            if (row != '123') const SizedBox(height: 8),
            Row(
              children: [
                for (var index = 0; index < row.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(child: _buildKey(row[index])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  VoidCallback? _tapAction(VoidCallback action, {required bool available}) {
    if (!enabled || !available) return null;
    return () {
      if (soundEnabled) GameTapSound.play();
      action();
    };
  }

  Widget _buildKey(String key) {
    final minimumSize = Size(0, rowHeight);
    final iconSize = (rowHeight * 0.48).clamp(28.0, 64.0);
    const padding = EdgeInsets.symmetric(vertical: 8);
    return switch (key) {
      '⌫' => Tooltip(
        message: 'Delete digit',
        excludeFromSemantics: true,
        child: FilledButton(
          onPressed: _tapAction(onDeletePressed, available: hasInput),
          style: FilledButton.styleFrom(
            minimumSize: minimumSize,
            padding: padding,
            backgroundColor: const Color(0xFFFFDBB5),
            foregroundColor: const Color(0xFF76351C),
            disabledBackgroundColor: const Color(0xFFFFEDD9),
            disabledForegroundColor: const Color(0xFF906B55),
          ),
          child: Icon(
            Icons.backspace_rounded,
            semanticLabel: 'Delete digit',
            size: iconSize,
          ),
        ),
      ),
      '✓' => Tooltip(
        message: 'Check answer',
        excludeFromSemantics: true,
        child: FilledButton(
          onPressed: _tapAction(onSubmitPressed, available: hasInput),
          style: FilledButton.styleFrom(
            minimumSize: minimumSize,
            padding: padding,
            backgroundColor: studyGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: studyMint,
            disabledForegroundColor: const Color(0xFF4D7666),
          ),
          child: Icon(
            Icons.check_rounded,
            semanticLabel: 'Check answer',
            size: iconSize,
          ),
        ),
      ),
      _ => FilledButton.tonal(
        onPressed: _tapAction(() => onNumberPressed(key), available: true),
        style: FilledButton.styleFrom(
          minimumSize: minimumSize,
          padding: padding,
        ),
        child: Text(
          key,
          style: TextStyle(
            fontSize: rowHeight >= 72 ? 36 : 26,
            fontFamily: 'BubblegumSans',
          ),
        ),
      ),
    };
  }
}
