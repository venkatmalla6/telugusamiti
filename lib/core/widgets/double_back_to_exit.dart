import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wraps a [child] with double-back-press-to-exit logic.
/// - First back press: shows a snackbar/toast "Press back again to exit".
/// - Second back press within [exitDuration]: exits the app.
class DoubleBackToExit extends StatefulWidget {
  final Widget child;
  final Duration exitDuration;
  final String message;

  const DoubleBackToExit({
    super.key,
    required this.child,
    this.exitDuration = const Duration(seconds: 2),
    this.message = 'Press back again to exit',
  });

  @override
  State<DoubleBackToExit> createState() => _DoubleBackToExitState();
}

class _DoubleBackToExitState extends State<DoubleBackToExit> {
  DateTime? _lastBackPressed;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > widget.exitDuration) {
      _lastBackPressed = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.message),
          duration: widget.exitDuration,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return false; // Don't pop/exit yet
    }
    // Second press within duration — exit
    await SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _onWillPop();
        }
      },
      child: widget.child,
    );
  }
}
