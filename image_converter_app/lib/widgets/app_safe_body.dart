import 'package:flutter/material.dart';

/// AppSafeBody - A Wrapper Widget to prevent overflow issues.
/// 
/// Helps wraps the content in a SingleChildScrollView with Constraints
/// to ensure it takes up at least the full screen height (for background colors),
/// but allows scrolling when content overflows or keyboard appears.
class AppSafeBody extends StatelessWidget {
  final Widget child;
  final bool enableScroll;
  final bool useSafeArea;
  final EdgeInsets padding;
  final bool tapToDismissKeyboard;

  const AppSafeBody({
    super.key,
    required this.child,
    this.enableScroll = true,
    this.useSafeArea = true,
    this.padding = const EdgeInsets.all(16.0),
    this.tapToDismissKeyboard = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget body = LayoutBuilder(
      builder: (context, constraints) {
        // If scrolling is disabled, just return the content.
        if (!enableScroll) {
          return Padding(
            padding: padding,
            child: child,
          );
        }

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // Ensure minimum height matches the screen height
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        );
      },
    );

    // Optional: Wrap in SafeArea
    if (useSafeArea) {
      body = SafeArea(child: body);
    }

    // Optional: Tap anywhere to dismiss keyboard
    if (tapToDismissKeyboard) {
      body = GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent, // Allow touches to pass through empty areas
        child: body,
      );
    }

    return body;
  }
}
