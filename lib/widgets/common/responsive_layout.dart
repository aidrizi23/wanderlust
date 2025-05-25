import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? watch;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.watch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < BreakPoints.mobile) {
          return watch ?? mobile;
        } else if (constraints.maxWidth < BreakPoints.tablet) {
          return mobile;
        } else if (constraints.maxWidth < BreakPoints.desktop) {
          return tablet ?? desktop;
        } else {
          return desktop;
        }
      },
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = DeviceType.fromWidth(constraints.maxWidth);
        return builder(context, deviceType);
      },
    );
  }
}

class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T desktop;
  final T? watch;

  const ResponsiveValue({
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.watch,
  });

  T resolve(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < BreakPoints.mobile) {
      return watch ?? mobile;
    } else if (width < BreakPoints.tablet) {
      return mobile;
    } else if (width < BreakPoints.desktop) {
      return tablet ?? desktop;
    } else {
      return desktop;
    }
  }
}

class BreakPoints {
  static const double mobile = 450;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;

  // Additional breakpoints for specific use cases
  static const double smallMobile = 320;
  static const double largeMobile = 576;
  static const double smallTablet = 768;
  static const double largeTablet = 992;
  static const double smallDesktop = 1024;
  static const double mediumDesktop = 1200;
  static const double xlDesktop = 1600;
}

enum DeviceType {
  watch,
  mobile,
  tablet,
  desktop,
  largeDesktop;

  static DeviceType fromWidth(double width) {
    if (width < BreakPoints.mobile) {
      return DeviceType.watch;
    } else if (width < BreakPoints.tablet) {
      return DeviceType.mobile;
    } else if (width < BreakPoints.desktop) {
      return DeviceType.tablet;
    } else if (width < BreakPoints.largeDesktop) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  bool get isMobile => this == DeviceType.mobile || this == DeviceType.watch;
  bool get isTablet => this == DeviceType.tablet;
  bool get isDesktop =>
      this == DeviceType.desktop || this == DeviceType.largeDesktop;
  bool get isLargeDesktop => this == DeviceType.largeDesktop;
}

extension ResponsiveExtensions on BuildContext {
  DeviceType get deviceType {
    final width = MediaQuery.of(this).size.width;
    return DeviceType.fromWidth(width);
  }

  bool get isMobile => deviceType.isMobile;
  bool get isTablet => deviceType.isTablet;
  bool get isDesktop => deviceType.isDesktop;
  bool get isLargeDesktop => deviceType.isLargeDesktop;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  EdgeInsets get responsivePadding {
    if (isMobile) {
      return const EdgeInsets.all(16);
    } else if (isTablet) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  double get responsiveRadius {
    if (isMobile) {
      return 12;
    } else if (isTablet) {
      return 16;
    } else {
      return 20;
    }
  }

  int get gridCrossAxisCount {
    if (screenWidth < BreakPoints.tablet) {
      return 1;
    } else if (screenWidth < BreakPoints.desktop) {
      return 2;
    } else if (screenWidth < BreakPoints.largeDesktop) {
      return 3;
    } else {
      return 4;
    }
  }

  int get tourGridCrossAxisCount {
    if (screenWidth < 600) {
      return 1; // Single column on small mobile
    } else if (screenWidth < 900) {
      return 2; // Two columns on large mobile/small tablet
    } else if (screenWidth < 1200) {
      return 3; // Three columns on tablet/small desktop
    } else if (screenWidth < 1600) {
      return 4; // Four columns on desktop
    } else {
      return 5; // Five columns on large desktop
    }
  }

  double get tourCardAspectRatio {
    if (isMobile) {
      return 0.85;
    } else if (isTablet) {
      return 0.75;
    } else {
      return 0.7;
    }
  }

  double get maxContentWidth {
    if (isMobile) {
      return double.infinity;
    } else if (isTablet) {
      return 768;
    } else {
      return 1200;
    }
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final bool center;

  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.center = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? context.maxContentWidth,
      ),
      padding: padding ?? context.responsivePadding,
      child: child,
    );

    if (center && !context.isMobile) {
      content = Center(child: content);
    }

    return content;
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.crossAxisCount,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 1.0,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final count = crossAxisCount ?? context.gridCrossAxisCount;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: children.length,
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}

class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool wrapOnMobile;

  const ResponsiveRow({
    Key? key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrapOnMobile = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (wrapOnMobile && context.isMobile) {
      return Column(
        crossAxisAlignment:
            crossAxisAlignment == CrossAxisAlignment.center
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
        children:
            children
                .expand((child) => [child, const SizedBox(height: 8)])
                .take(children.length * 2 - 1)
                .toList(),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }
}

class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const AdaptiveScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: context.isMobile ? drawer : null,
      endDrawer: context.isMobile ? endDrawer : null,
      body:
          context.isDesktop && (drawer != null || endDrawer != null)
              ? Row(
                children: [
                  if (drawer != null) SizedBox(width: 280, child: drawer),
                  Expanded(child: body),
                  if (endDrawer != null) SizedBox(width: 280, child: endDrawer),
                ],
              )
              : body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: context.isMobile ? bottomNavigationBar : null,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
