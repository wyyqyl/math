import 'package:flutter/material.dart';

class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onSubmitPressed;

  const NumericKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onDeletePressed,
    required this.onSubmitPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildKeypadRow(['1', '2', '3']),
          const SizedBox(height: 12),
          _buildKeypadRow(['4', '5', '6']),
          const SizedBox(height: 12),
          _buildKeypadRow(['7', '8', '9']),
          const SizedBox(height: 12),
          _buildKeypadRow(['⌫', '0', '✓']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeypadButton(key)).toList(),
    );
  }

  Widget _buildKeypadButton(String key) {
    final isDelete = key == '⌫';
    final isSubmit = key == '✓';
    final isNumber = !isDelete && !isSubmit;

    Color backgroundColor;
    Color textColor;

    if (isSubmit) {
      backgroundColor = Colors.green.shade400;
      textColor = Colors.white;
    } else if (isDelete) {
      backgroundColor = Colors.red.shade400;
      textColor = Colors.white;
    } else {
      backgroundColor = Colors.white;
      textColor = Colors.orange.shade900;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          elevation: 4,
          child: InkWell(
            onTap: () {
              if (isDelete) {
                onDeletePressed();
              } else if (isSubmit) {
                onSubmitPressed();
              } else {
                onNumberPressed(key);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 70,
              alignment: Alignment.center,
              child: Text(
                key,
                style: TextStyle(
                  fontSize: isNumber ? 32 : 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
