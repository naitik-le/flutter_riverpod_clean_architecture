import 'package:flutter/material.dart';

/// ResponsiveLayout utilizes [LayoutBuilder] to select between
/// Mobile, Tablet, and Desktop widgets. It serves as the primary responsive
/// backbone for Collaborative Workspace views on Web and Mobile platforms.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget? tabletBody;
  final Widget desktopBody;

  const ResponsiveLayout({super.key, required this.mobileBody, this.tabletBody, required this.desktopBody});

  // Screen Width Breakpoints
  static const double mobileMaxBreakpoint = 600.0;
  static const double tabletMaxBreakpoint = 1024.0;

  /// Helper to check if the current screen width is mobile scale
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= mobileMaxBreakpoint;
  }

  /// Helper to check if the current screen width is tablet scale
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileMaxBreakpoint && width <= tabletMaxBreakpoint;
  }

  /// Helper to check if the current screen width is desktop/web scale
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > tabletMaxBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= mobileMaxBreakpoint) {
          return mobileBody;
        } else if (constraints.maxWidth <= tabletMaxBreakpoint) {
          // If tabletBody is not provided, fall back dynamically to desktopBody
          return tabletBody ?? desktopBody;
        } else {
          return desktopBody;
        }
      },
    );
  }
}
