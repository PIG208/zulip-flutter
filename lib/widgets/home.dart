import 'package:flutter/material.dart';

import '../generated/l10n/zulip_localizations.dart';
import '../model/narrow.dart';
import 'action_sheet.dart';
import 'content.dart';
import 'icons.dart';
import 'inbox.dart';
import 'inset_shadow.dart';
import 'message_list.dart';
import 'page.dart';
import 'profile.dart';
import 'recent_dm_conversations.dart';
import 'store.dart';
import 'subscription_list.dart';
import 'text.dart';
import 'theme.dart';

enum HomePageTab {
  inbox,
  channels,
  directMessages,
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.initialTab});

  static Route<void> buildRoute({required int accountId, HomePageTab? initialTab}) {
    return MaterialAccountWidgetRoute(accountId: accountId,
      page: HomePage(initialTab: initialTab ?? HomePageTab.inbox));
  }

  final HomePageTab initialTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ValueNotifier<HomePageTab> _tab = ValueNotifier(widget.initialTab);

  @override
  void initState() {
    super.initState();
    _tab.addListener(_tabChanged);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _tabChanged() {
    setState(() {
      // The actual state lives in [_tab]
    });
  }

  @override
  Widget build(BuildContext context) {
    const pageBodies = {
      HomePageTab.inbox:          InboxPageBody(),
      HomePageTab.channels:       SubscriptionListPageBody(),
      // Users
      HomePageTab.directMessages: RecentDmConversationsPageBody(),
    };

    Widget Function(HomePageTab tab) buildButton(IconData icon, String tooltip) {
      return (tab) => NavigationButton(
        icon: icon, tooltip: tooltip,
        selected: _tab.value == tab,
        onPressed: () {
          setState(() {
            _tab.value = tab;
          });
        });
    }

    final designVariables = DesignVariables.of(context);

    final navigationButtonBuilders = {
      HomePageTab.inbox:          buildButton(ZulipIcons.inbox,       'Inbox'),
      HomePageTab.channels:       buildButton(ZulipIcons.hash_italic, 'Channels'),
      // navigationButtonBuilder(ZulipIcons.contacts, 'Users'),
      HomePageTab.directMessages: buildButton(ZulipIcons.user,        'Direct messages'),
    };
    final menuButton = NavigationButton(
      icon: ZulipIcons.menu, tooltip: 'Menu', selected: false,
      onPressed: () => _showMenu(context, tab: _tab));

    return Scaffold(
      body: Stack(
        children: [
          for (final MapEntry(key:tab, value:body) in pageBodies.entries)
            Offstage(offstage: tab != _tab.value, child: body)
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
                  for (final MapEntry(key:tab, value:buildButton) in navigationButtonBuilders.entries)
                    Expanded(child: buildButton(tab)),
                  Expanded(child: menuButton),
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

void _showMenu(BuildContext context, {
  required ValueNotifier<HomePageTab> tab,
}) {
  final designVariables = DesignVariables.of(context);
  final menuItems = <Widget>[
    // Search
    // const SizedBox(height: 8),
    _InboxButton(tab: tab),
    // Recent conversations
    const _MentionsButton(),
    const _StarredMessagesButton(),
    // Drafts
    _DirectMessages(tab: tab),
    _ChannelsButton(tab: tab),
    // Users
    const _MyProfileButton(),
    // Set my status
    // const SizedBox(height: 8),
    // Settings
    // Notifications
    // const SizedBox(height: 8),
    // VersionInfo
  ];

  final accountId = PerAccountStoreWidget.accountIdOf(context);

  showModalBottomSheet<void>(
    context: context,
    // Clip.hardEdge looks bad; Clip.antiAliasWithSaveLayer looks pixel-perfect
    // on my iPhone 13 Pro but is marked as "much slower":
    //   https://api.flutter.dev/flutter/dart-ui/Clip.html
    clipBehavior: Clip.antiAlias,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: designVariables.bgBotBar,
    builder: (BuildContext _) {
      return PerAccountStoreWidget(
        accountId: accountId,
        child: SafeArea(
          minimum: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(child: InsetShadowBox(
                top: 8, bottom: 8,
                color: designVariables.bgBotBar,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: menuItems)))),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Scaled(
                  scaleEnd: 0.95,
                  duration: Duration(milliseconds: 100),
                  child: SizedBox(height: 44, child: ActionSheetCancelButton()))),
            ])));
    });
}

abstract class _MenuButton extends StatelessWidget {
  const _MenuButton();

  String label(ZulipLocalizations zulipLocalizations);

  bool get selected => false;
  IconData get icon;
  Widget buildLeading(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    return Icon(icon, size: 24, color: selected ? designVariables.iconSelected
                                                : designVariables.icon);
  }

  Widget buildTrailing(BuildContext context) => const SizedBox.shrink();

  void onPressed(BuildContext context);

  @override
  Widget build(BuildContext context) {
    final designVariables = DesignVariables.of(context);
    final zulipLocalizations = ZulipLocalizations.of(context);

    final borderSide = BorderSide(width: 1,
      strokeAlign: BorderSide.strokeAlignOutside,
      color: designVariables.borderMenuButtonSelected);
    final buttonStyle = TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        foregroundColor: designVariables.labelMenuButton,
        splashFactory: NoSplash.splashFactory,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ).copyWith(
        backgroundColor: WidgetStateColor.fromMap({
          WidgetState.pressed: designVariables.bgMenuButtonActive,
          ~WidgetState.pressed: selected ? designVariables.bgMenuButtonSelected
                                         : Colors.transparent,
        }),
        side: WidgetStateBorderSide.fromMap({
          WidgetState.pressed: null,
          ~WidgetState.pressed: selected ? borderSide : null,
        }));

    return Scaled(
      duration: const Duration(milliseconds: 100),
      scaleEnd: 0.95,
      child: SizedBox(height: 44,
        child: TextButton(
          onPressed: () => onPressed(context),
          style: buttonStyle,
          child: Row(spacing: 8, children: [
            buildLeading(context),
            Expanded(child: Text(label(zulipLocalizations),
              textAlign: TextAlign.start,
              style: const TextStyle(fontSize: 19, height: 26 / 19)
                .merge(weightVariableTextStyle(context, wght: selected ? 600 : 400)))),
            buildTrailing(context),
          ]))));
  }
}

abstract class _NavigationBarMenuButton extends _MenuButton {
  const _NavigationBarMenuButton({required this.tab});

  final ValueNotifier<HomePageTab> tab;

  HomePageTab get target;

  @override
  bool get selected => tab.value == target;

  @override
  void onPressed(BuildContext context) async {
    tab.value = target;
    Navigator.of(context).pop();
  }
}

class _InboxButton extends _NavigationBarMenuButton {
  const _InboxButton({required super.tab});

  @override
  IconData get icon => ZulipIcons.inbox;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.inboxPageTitle;
  }

  @override
  HomePageTab get target => HomePageTab.inbox;
}

class _DirectMessages extends _NavigationBarMenuButton {
  const _DirectMessages({required super.tab});

  @override
  IconData get icon => ZulipIcons.user;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.recentDmConversationsPageTitle;
  }

  @override
  HomePageTab get target => HomePageTab.directMessages;
}

class _ChannelsButton extends _NavigationBarMenuButton {
  const _ChannelsButton({required super.tab});

  @override
  IconData get icon => ZulipIcons.hash_italic;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.channelsPageTitle;
  }

  @override
  HomePageTab get target => HomePageTab.channels;
}

class _MentionsButton extends _MenuButton {
  const _MentionsButton();

  @override
  IconData get icon => ZulipIcons.at_sign;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.mentionsPageTitle;
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(MessageListPage.buildRoute(
      context: context, narrow: const MentionsNarrow()));
  }
}

class _StarredMessagesButton extends _MenuButton {
  const _StarredMessagesButton();

  @override
  IconData get icon => ZulipIcons.star;

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.starredMessagesPageTitle;
  }

  @override
  void onPressed(BuildContext context) {
    Navigator.of(context).push(MessageListPage.buildRoute(
      context: context, narrow: const StarredMessagesNarrow()));
  }
}

class _MyProfileButton extends _MenuButton {
  const _MyProfileButton();

  @override
  IconData get icon => ZulipIcons.user;

  @override
  Widget buildLeading(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    return Avatar(userId: store.selfUserId, size: 24, borderRadius: 4);
  }

  @override
  String label(ZulipLocalizations zulipLocalizations) {
    return zulipLocalizations.profilePageTitle;
  }

  @override
  void onPressed(BuildContext context) {
    final store = PerAccountStoreWidget.of(context);
    Navigator.of(context).push(
      ProfilePage.buildRoute(context: context, userId: store.selfUserId));
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
