import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../api/model/submessage.dart';
import '../api/route/submessage.dart';
import 'content.dart';
import 'store.dart';
import 'text.dart';

class PollWidget extends StatefulWidget {
  const PollWidget({super.key, required this.messageId, required this.poll});

  final int messageId;
  final Poll poll;

  @override
  State<PollWidget> createState() => _PollWidgetState();
}

class _PollWidgetState extends State<PollWidget> {
  @override
  void initState() {
    super.initState();
    widget.poll.addListener(_modelChanged);
  }

  @override
  void didUpdateWidget(covariant PollWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.poll != oldWidget.poll) {
      oldWidget.poll.removeListener(_modelChanged);
      widget.poll.addListener(_modelChanged);
    }
  }

  @override
  void dispose() {
    widget.poll.removeListener(_modelChanged);
    super.dispose();
  }

  void _modelChanged() {
    setState(() {
      // The actual state lives in the [Poll] model.
      // This method was called because that just changed.
    });
  }

  void toggleVote(PollOption option) async {
    final store = PerAccountStoreWidget.of(context);
    final optionKey = widget.poll.getOptionKey(option)!;
    // The poll data in store might be obselete before we get the event
    // that updates it.  This is fine because the result will be consistent
    // eventually, regardless of the possible duplicate requests.
    final op = widget.poll.hasUserVotedFor(userId: store.selfUserId, option: option)
      ? PollVoteOp.remove
      : PollVoteOp.add;
    unawaited(sendSubmessage(store.connection, messageId: widget.messageId,
      content: PollVoteEventSubmessage(key: optionKey, op: op)));
  }

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final theme = ContentTheme.of(context);
    final store = PerAccountStoreWidget.of(context);

    final textStyleBold = weightVariableTextStyle(context, wght: 600);
    final textStyleVoterNames = TextStyle(
      fontSize: 16, color: theme.colorPollNames);

    Text question = (widget.poll.question.isNotEmpty)
      ? Text(widget.poll.question, style: textStyleBold.copyWith(fontSize: 18))
      : Text(zulipLocalizations.pollWidgetQuestionMissing,
          style: textStyleBold.copyWith(fontSize: 18, fontStyle: FontStyle.italic));

    Widget buildOptionItem(PollOption option) {
      // TODO(i18n): List formatting, like you can do in JavaScript:
      //   new Intl.ListFormat('ja').format(['Chris', 'Greg', 'Alya', 'Zixuan'])
      //   // 'Chris、Greg、Alya、Zixuan'
      final voterNames = option.voters
        .map((userId) =>
          store.users[userId]?.fullName ?? zulipLocalizations.unknownUserName)
        .join(', ');

      return Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          spacing: 5,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: localizedTextBaseline(context),
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.square(44),
                // The default visual density is platform dependent.
                // For those whose density defaults to [VisualDensity.compact],
                // this button would be 8px smaller if we do not override it.
                //
                // See also:
                // * [ThemeData.visualDensity], which provides the default.
                visualDensity: VisualDensity.standard,
                // This padding is only in effect
                // when the vote count has more than one digit.
                padding: const EdgeInsets.symmetric(horizontal: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3)),
                backgroundColor: theme.colorPollVoteCountBackground,
                side: BorderSide(color: theme.colorPollVoteCountBorder),
                splashFactory: NoSplash.splashFactory,
              ),
              onPressed: () => toggleVote(option),
              child: Text(option.voters.length.toString(),
                textAlign: TextAlign.center,
                style: textStyleBold.copyWith(fontSize: 16,
                  color: theme.colorPollVoteCountText))),
            Expanded(
              child: Wrap(
                spacing: 5,
                children: [
                  Text(option.text, style: textStyleBold.copyWith(fontSize: 16)),
                  if (option.voters.isNotEmpty)
                    // TODO(i18n): Localize parenthesis characters.
                    Text('($voterNames)', style: textStyleVoterNames),
                ])),
          ]));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 6), child: question),
        if (widget.poll.options.isEmpty)
          Text(zulipLocalizations.pollWidgetOptionsMissing,
            style: textStyleVoterNames.copyWith(fontStyle: FontStyle.italic)),
        for (final option in widget.poll.options)
          buildOptionItem(option),
      ]);
  }
}
