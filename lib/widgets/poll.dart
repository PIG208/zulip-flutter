import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/zulip_localizations.dart';

import '../api/model/submessage.dart';
import 'content.dart';
import 'store.dart';
import 'text.dart';

class PollWidget extends StatelessWidget {
  const PollWidget({super.key, required this.poll});

  final Poll poll;

  @override
  Widget build(BuildContext context) {
    final zulipLocalizations = ZulipLocalizations.of(context);
    final store = PerAccountStoreWidget.of(context);
    final theme = ContentTheme.of(context);

    final textStylePollBold = const TextStyle(fontSize: 18)
      .merge(weightVariableTextStyle(context, wght: 600));
    final textStylePollNames = TextStyle(
      fontSize: 16, color: theme.colorPollNames);

    String getOptionVoterNames(PollOption option) => option.voters.map((userId) =>
      store.users[userId]?.fullName
        ?? zulipLocalizations.unknownUserName).join(', ');

    final optionTiles = [
      for (final option in poll.options)
        Padding(
          padding: const EdgeInsets.only(bottom: 5.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 25,
                height: 25,
                decoration: BoxDecoration(
                  color: theme.colorPollVoteCountBackground,
                  border: Border.all(color: theme.colorPollVoteCountBorder),
                  borderRadius: BorderRadius.circular(3)),
                child: Center(
                  child: Text(option.voters.length.toString(),
                    style: textStylePollBold
                      .copyWith(color: theme.colorPollVoteCountText, fontSize: 13),
                    textAlign: TextAlign.center))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 5.0),
                  child: Wrap(children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 5.0),
                      child: Text(option.text,
                        style: textStylePollBold.copyWith(fontSize: 16))),
                    if (option.voters.isNotEmpty)
                      Text('(${getOptionVoterNames(option)})', style: textStylePollNames),
                  ]))),
            ])),
    ];

    Text question = (poll.question.isNotEmpty)
      ? Text(poll.question, style: textStylePollBold)
      : Text(zulipLocalizations.pollWidgetQuestionMissing,
        style: textStylePollBold.copyWith(fontStyle: FontStyle.italic));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 6.0), child: question),
        if (optionTiles.isEmpty)
          Text(zulipLocalizations.pollWidgetOptionsMissing,
            style: textStylePollNames.copyWith(fontStyle: FontStyle.italic)),
        ...optionTiles
      ]);
  }
}
