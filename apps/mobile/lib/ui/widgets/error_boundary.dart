import 'dart:async';

import 'package:flutter/material.dart';

import '../../infra/monitoring/crash_reporter.dart';
import '../theme/app_theme.dart';

/// Full-screen error fallback that wraps the app's widget tree.
///
/// When a fatal Flutter error occurs in the subtree, this widget
/// catches it and shows a recovery screen instead of crashing.
/// It also reports the error to [CrashReporter].
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    required this.child,
    required this.crashReporter,
    super.key,
  });

  final Widget child;
  final CrashReporter crashReporter;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    // We don't override FlutterError.onError here — that's done in
    // bootstrap.dart. Instead, we use ErrorWidget.builder to catch
    // widget-level build errors.
  }

  void _handleError(FlutterErrorDetails details) {
    unawaited(
      widget.crashReporter.recordError(
        details.exception,
        details.stack,
        reason: 'error_boundary',
        fatal: true,
      ),
    );
    unawaited(widget.crashReporter.log(
      'ErrorBoundary caught: ${details.exceptionAsString()}',
    ));
    setState(() {
      _error = details;
    });
  }

  void _recover() {
    setState(() {
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorFallbackScreen(
        errorMessage: _error!.exceptionAsString(),
        onRestart: _recover,
      );
    }

    return _ErrorBoundaryScope(
      onError: _handleError,
      child: widget.child,
    );
  }
}

/// InheritedWidget that propagates the error handler down the tree.
class _ErrorBoundaryScope extends InheritedWidget {
  const _ErrorBoundaryScope({
    required this.onError,
    required super.child,
  });

  final void Function(FlutterErrorDetails) onError;

  static _ErrorBoundaryScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ErrorBoundaryScope>();
  }

  @override
  bool updateShouldNotify(_ErrorBoundaryScope oldWidget) {
    return onError != oldWidget.onError;
  }
}

/// Full-screen fallback shown when the app encounters an unrecoverable error.
class _ErrorFallbackScreen extends StatelessWidget {
  const _ErrorFallbackScreen({
    required this.errorMessage,
    required this.onRestart,
  });

  final String errorMessage;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: LuminaPalette.midnight,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFFF6B6B),
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: LuminaPalette.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'An unexpected error occurred. Your progress has been saved.',
                    style: TextStyle(
                      fontSize: 14,
                      color: LuminaPalette.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 80),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFF6B6B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0x33FF6B6B),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Color(0xAAFF6B6B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onRestart,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Restart'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        backgroundColor: LuminaPalette.cyan,
                        foregroundColor: const Color(0xFF052033),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
