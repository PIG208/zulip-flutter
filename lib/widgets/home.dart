import 'package:flutter/material.dart';

import 'icons.dart';
import 'inbox.dart';
import 'page.dart';
import 'recent_dm_conversations.dart';
import 'subscription_list.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static Route<void> buildRoute({required int accountId}) {
    return MaterialAccountWidgetRoute(accountId: accountId,
      page: const HomePage());
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    const pageBodies = [
      InboxPageBody(),
      SubscriptionListPageBody(),
      // Users
      RecentDmConversationsPageBody(),
      // Menu
    ];

    Widget Function(int pageIndex) navigationButtonBuilder(IconData icon, String tooltip) {
      return (pageIndex) => NavigationButton(
        icon: icon, tooltip: tooltip,
        selected: _pageIndex == pageIndex,
        onPressed: () {
          setState(() {
            _pageIndex = pageIndex;
          });
        });
    }

    final navigationButtonBuilders = [
      navigationButtonBuilder(ZulipIcons.inbox,       'Inbox'),
      navigationButtonBuilder(ZulipIcons.hash_italic, 'Channels'),
      // navigationButtonBuilder(ZulipIcons.contacts, 'Users'),
      navigationButtonBuilder(ZulipIcons.user,        'Direct messages'),
      // navigationButtonBuilder(ZulipIcons.menu,     'Menu'),
    ];

    final designVariables = DesignVariables.of(context);

    return Scaffold(
      body: Stack(
        children: [
          for (int index = 0; index < pageBodies.length; index++)
            Offstage(offstage: index != _pageIndex, child: pageBodies[index])
        ]),
      bottomNavigationBar: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: designVariables.borderBar, width: 0)),
            color: designVariables.bgBotBar),
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              // TODO(design): determine a suitable max width
              constraints: const BoxConstraints(maxWidth: 600).tighten(height: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (pageIndex, buildButton) in navigationButtonBuilders.indexed)
                    Expanded(child: buildButton(pageIndex)),
                ]))))));
  }
}

class NavigationButton extends StatelessWidget {
  const NavigationButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);

    final iconColor = WidgetStateColor.fromMap({
      WidgetState.pressed:  designVariables.iconSelected,
      ~WidgetState.pressed: selected ? designVariables.iconSelected
                                     : designVariables.icon,
    });

    return Scaled(
      scaleEnd: 0.875,
      duration: const Duration(milliseconds: 100),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          // TODO(#417): Disable splash effects for all buttons globally.
          splashFactory: NoSplash.splashFactory,
          highlightColor: designVariables.iconSelected.withValues(alpha: 0.05),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4))),
        ).copyWith(foregroundColor: iconColor)));
  }
}

class Scaled extends StatefulWidget {
  const Scaled({
    super.key,
    required this.scaleEnd,
    required this.duration,
    required this.child,
  });

  final double scaleEnd;
  final Duration duration;
  final Widget child;

  @override
  State<Scaled> createState() => _ScaledState();
}

class _ScaledState extends State<Scaled> {
  double _scale = 1;

  void _changeScale(double scale) {
    setState(() {
      _scale = scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) =>  _changeScale(widget.scaleEnd),
      onTapUp: (_) =>    _changeScale(1),
      onTapCancel: () => _changeScale(1),
      child: AnimatedScale(
        scale: _scale,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child));
  }
}
