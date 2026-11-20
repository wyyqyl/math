import 'package:material_ui/material_ui.dart';

import 'study_layout.dart';

class MultiplicationArray extends StatelessWidget {
  const MultiplicationArray({
    super.key,
    required this.rows,
    required this.columns,
  });

  final int rows;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$rows ${rows == 1 ? 'group' : 'groups'} of $columns dots',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var row = 0; row < rows; row++)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        children: [
                          for (var column = 0; column < columns; column++)
                            Container(
                              width: 13,
                              height: 13,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: row.isEven
                                    ? studyBlue
                                    : const Color(0xFF7B8CE3),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$rows ${rows == 1 ? 'group' : 'groups'} of $columns'),
          ],
        ),
      ),
    );
  }
}
