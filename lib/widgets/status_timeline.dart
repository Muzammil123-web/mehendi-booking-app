import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// A horizontal step tracker, e.g. Requested -> Confirmed -> Completed.
/// Pass the full ordered list of stage labels and the index the item is
/// currently at. If [isCancelled] is true, everything renders in the
/// "error" color to show the flow was interrupted instead of completed.
class StatusTimeline extends StatelessWidget {
  final List<String> stages;
  final int currentIndex;
  final bool isCancelled;

  const StatusTimeline({
    super.key,
    required this.stages,
    required this.currentIndex,
    this.isCancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          // connector line between two stage dots
          final stageIndex = (i - 1) ~/ 2;
          final filled = stageIndex < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: filled
                  ? (isCancelled ? AppColors.error : AppColors.success)
                  : AppColors.textLight.withOpacity(0.25),
            ),
          );
        }
        final stageIndex = i ~/ 2;
        final isDone = stageIndex < currentIndex;
        final isCurrent = stageIndex == currentIndex;
        Color dotColor;
        if (isCancelled && isCurrent) {
          dotColor = AppColors.error;
        } else if (isDone || isCurrent) {
          dotColor = AppColors.success;
        } else {
          dotColor = AppColors.textLight.withOpacity(0.25);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
              child: (isDone || (isCurrent && !isCancelled))
                  ? const Icon(Icons.check, size: 11, color: Colors.white)
                  : (isCurrent && isCancelled)
                      ? const Icon(Icons.close, size: 11, color: Colors.white)
                      : null,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 62,
              child: Text(
                stages[stageIndex],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent
                      ? (isCancelled ? AppColors.error : AppColors.textDark)
                      : AppColors.textLight,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
