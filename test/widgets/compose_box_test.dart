import 'dart:async';
import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/events.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';
import 'package:zulip/api/route/messages.dart';
import 'package:zulip/model/binding.dart';
import 'package:zulip/model/localizations.dart';
import 'package:zulip/model/narrow.dart';
import 'package:zulip/model/store.dart';
import 'package:zulip/model/typing_status.dart';
import 'package:zulip/widgets/app.dart';
import 'package:zulip/widgets/compose_box.dart';
import 'package:zulip/widgets/page.dart';

import '../api/fake_api.dart';
import '../example_data.dart' as eg;
import '../flutter_checks.dart';
import '../model/binding.dart';
import '../model/test_store.dart';
import '../model/typing_status_test.dart';
import '../stdlib_checks.dart';
import 'dialog_checks.dart';
import 'test_app.dart';

void main() {
  TestZulipBinding.ensureInitialized();

  late PerAccountStore store;
  late FakeApiConnection connection;

  final topicInputFinder = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.controller is ComposeTopicController);
  final contentInputFinder = find.byWidgetPredicate(
    (widget) => widget is TextField && widget.controller is ComposeContentController);

  Future<GlobalKey<ComposeBoxController>> prepareComposeBox(
    WidgetTester tester, {
    required Narrow narrow,
    String? topic,
    String? content,
    List<User> users = const [],
  }) async {
    addTearDown(testBinding.reset);
    await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

    store = await testBinding.globalStore.perAccount(eg.selfAccount.id);

    await store.addUsers([eg.selfUser, ...users]);
    connection = store.connection as FakeApiConnection;

    final controllerKey = GlobalKey<ComposeBoxController>();
    await tester.pumpWidget(TestZulipApp(accountId: eg.selfAccount.id,
      child: Column(
        // This positions the compose box at the bottom of the screen,
        // simulating the layout of the message list page.
        children: [
          const Expanded(child: SizedBox.expand()),
          ComposeBox(controllerKey: controllerKey, narrow: narrow),
        ])));
    await tester.pumpAndSettle();

    if (topic != null) {
      // The topic input is currently only available to ChannelNarrow.
      narrow as ChannelNarrow;
      connection.prepare(body:
        jsonEncode(GetStreamTopicsResult(topics: [eg.getStreamTopicsEntry()]).toJson()));
      await tester.enterText(topicInputFinder, topic);
      check(connection.takeRequests()).single
        ..method.equals('GET')
        ..url.path.equals('/api/v1/users/me/${narrow.streamId}/topics');
    }
    if (content != null) {
      await tester.enterText(contentInputFinder, content);
    }
    await tester.pump();

    return controllerKey;
  }

  group('ComposeContentController', () {
    group('insertPadded', () {
      // Like `parseMarkedText` in test/model/autocomplete_test.dart,
      //   but a bit different -- could maybe deduplicate some.
      TextEditingValue parseMarkedText(String markedText) {
        final textBuffer = StringBuffer();
        int? insertionPoint;
        int i = 0;
        for (final char in markedText.codeUnits) {
          if (char == 94 /* ^ */) {
            if (insertionPoint != null) {
              throw Exception('Test error: too many ^ in input');
            }
            insertionPoint = i;
            continue;
          }
          textBuffer.writeCharCode(char);
          i++;
        }
        if (insertionPoint == null) {
          throw Exception('Test error: expected ^ in input');
        }
        return TextEditingValue(text: textBuffer.toString(), selection: TextSelection.collapsed(offset: insertionPoint));
      }

      /// Test the given `insertPadded` call, in a convenient format.
      ///
      /// In valueBefore, represent the insertion point as "^".
      /// In expectedValue, represent the collapsed selection as "^".
      void testInsertPadded(String description, String valueBefore, String textToInsert, String expectedValue) {
        test(description, () {
          final controller = ComposeContentController();
          controller.value = parseMarkedText(valueBefore);
          controller.insertPadded(textToInsert);
          check(controller.value).equals(parseMarkedText(expectedValue));
        });
      }

      // TODO(?) exercise the part of insertPadded that chooses the insertion
      //   point based on [TextEditingValue.selection], which may be collapsed,
      //   expanded, or null (what they call !TextSelection.isValid).

      testInsertPadded('empty; insert one line',
        '^', 'a\n',    'a\n\n^');
      testInsertPadded('empty; insert two lines',
        '^', 'a\nb\n', 'a\nb\n\n^');

      group('insert at end', () {
        testInsertPadded('one empty line; insert one line',
          '\n^',     'a\n',    '\na\n\n^');
        testInsertPadded('two empty lines; insert one line',
          '\n\n^',   'a\n',    '\n\na\n\n^');
        testInsertPadded('one line, incomplete; insert one line',
          'a^',      'b\n',    'a\n\nb\n\n^');
        testInsertPadded('one line, complete; insert one line',
          'a\n^',    'b\n',    'a\n\nb\n\n^');
        testInsertPadded('multiple lines, last is incomplete; insert one line',
          'a\nb^',   'c\n',    'a\nb\n\nc\n\n^');
        testInsertPadded('multiple lines, last is complete; insert one line',
          'a\nb\n^', 'c\n',    'a\nb\n\nc\n\n^');
        testInsertPadded('multiple lines, last is complete; insert two lines',
          'a\nb\n^', 'c\nd\n', 'a\nb\n\nc\nd\n\n^');
      });

      group('insert at start', () {
        testInsertPadded('one empty line; insert one line',
          '^\n',     'a\n',    'a\n\n^');
        testInsertPadded('two empty lines; insert one line',
          '^\n\n',   'a\n',    'a\n\n^\n');
        testInsertPadded('one line, incomplete; insert one line',
          '^a',      'b\n',    'b\n\n^a');
        testInsertPadded('one line, complete; insert one line',
          '^a\n',    'b\n',    'b\n\n^a\n');
        testInsertPadded('multiple lines, last is incomplete; insert one line',
          '^a\nb',   'c\n',    'c\n\n^a\nb');
        testInsertPadded('multiple lines, last is complete; insert one line',
          '^a\nb\n', 'c\n',    'c\n\n^a\nb\n');
        testInsertPadded('multiple lines, last is complete; insert two lines',
          '^a\nb\n', 'c\nd\n', 'c\nd\n\n^a\nb\n');
      });

      group('insert in middle', () {
        testInsertPadded('middle of line',
          'a^a\n',       'b\n', 'a\n\nb\n\n^a\n');
        testInsertPadded('start of non-empty line, after empty line',
          'b\n\n^a\n',   'c\n', 'b\n\nc\n\n^a\n');
        testInsertPadded('end of non-empty line, before non-empty line',
          'a^\nb\n',     'c\n', 'a\n\nc\n\n^b\n');
        testInsertPadded('start of non-empty line, after non-empty line',
          'a\n^b\n',     'c\n', 'a\n\nc\n\n^b\n');
        testInsertPadded('text start; one empty line; insertion point; one empty line',
          '\n^\n',       'a\n', '\na\n\n^');
        testInsertPadded('text start; one empty line; insertion point; two empty lines',
          '\n^\n\n',     'a\n', '\na\n\n^\n');
        testInsertPadded('text start; two empty lines; insertion point; one empty line',
          '\n\n^\n',     'a\n', '\n\na\n\n^');
        testInsertPadded('text start; two empty lines; insertion point; two empty lines',
          '\n\n^\n\n',   'a\n', '\n\na\n\n^\n');
      });
    });
  });

  group('ComposeBox textCapitalization', () {
    void checkComposeBoxTextFields(WidgetTester tester, {
      required GlobalKey<ComposeBoxController> controllerKey,
      required bool expectTopicTextField,
    }) {
      final composeBoxController = controllerKey.currentState!;

      final topicTextField = tester.widgetList<TextField>(find.byWidgetPredicate(
        (widget) => widget is TextField
          && widget.controller == composeBoxController.topicController)).singleOrNull;
      if (expectTopicTextField) {
        check(topicTextField).isNotNull()
          .textCapitalization.equals(TextCapitalization.none);
      } else {
        check(topicTextField).isNull();
      }

      final contentTextField = tester.widget<TextField>(find.byWidgetPredicate(
        (widget) => widget is TextField
          && widget.controller == composeBoxController.contentController));
      check(contentTextField)
        .textCapitalization.equals(TextCapitalization.sentences);
    }

    testWidgets('_StreamComposeBox', (tester) async {
      final key = await prepareComposeBox(tester,
        narrow: ChannelNarrow(eg.stream().streamId));
      checkComposeBoxTextFields(tester, controllerKey: key,
        expectTopicTextField: true);
    });

    testWidgets('_FixedDestinationComposeBox', (tester) async {
      final key = await prepareComposeBox(tester,
        narrow: TopicNarrow.ofMessage(eg.streamMessage()));
      checkComposeBoxTextFields(tester, controllerKey: key,
        expectTopicTextField: false);
    });
  });

  group('ComposeBox typing notices', () {
    const narrow = TopicNarrow(123, 'some topic');

    void checkTypingRequest(TypingOp op, SendableNarrow narrow) =>
      checkSetTypingStatusRequests(connection.takeRequests(), [(op, narrow)]);

    Future<void> checkStartTyping(WidgetTester tester, SendableNarrow narrow) async {
      connection.prepare(json: {});
      await tester.enterText(contentInputFinder, 'hello world');
      checkTypingRequest(TypingOp.start, narrow);
    }

    testWidgets('smoke TopicNarrow', (tester) async {
      await prepareComposeBox(tester, narrow: narrow);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, narrow);
    });

    testWidgets('smoke DmNarrow', (tester) async {
      final narrow = DmNarrow.withUsers(
        [eg.otherUser.userId], selfUserId: eg.selfUser.userId);
      await prepareComposeBox(tester, narrow: narrow);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, narrow);
    });

    testWidgets('smoke ChannelNarrow', (tester) async {
      const narrow = ChannelNarrow(123);
      final destinationNarrow = TopicNarrow(narrow.streamId, 'test topic');
      await prepareComposeBox(
        tester, narrow: narrow, topic: destinationNarrow.topic);

      await checkStartTyping(tester, destinationNarrow);

      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, destinationNarrow);
    });

    testWidgets('clearing text sends a "typing stopped" notice', (tester) async {
      await prepareComposeBox(tester, narrow: narrow);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      await tester.enterText(contentInputFinder, '');
      checkTypingRequest(TypingOp.stop, narrow);
    });

    testWidgets('hitting send button sends a "typing stopped" notice', (tester) async {
      await prepareComposeBox(tester, narrow: narrow);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      connection.prepare(json: SendMessageResult(id: 123).toJson());
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump(Duration.zero);
      final requests = connection.takeRequests();
      checkSetTypingStatusRequests([requests.first], [(TypingOp.stop, narrow)]);
      check(requests).length.equals(2);
    });

    Future<void> prepareComposeBoxWithNavigation(WidgetTester tester) async {
      addTearDown(testBinding.reset);
      await testBinding.globalStore.add(eg.selfAccount, eg.initialSnapshot());

      store = await testBinding.globalStore.perAccount(eg.selfAccount.id);
      connection = store.connection as FakeApiConnection;

      await tester.pumpWidget(const ZulipApp());
      await tester.pump();
      final navigator = await ZulipApp.navigator;
      unawaited(navigator.push(MaterialAccountWidgetRoute(
        accountId: eg.selfAccount.id, page: const ComposeBox(narrow: narrow))));
      await tester.pumpAndSettle();
    }

    testWidgets('navigating away sends a "typing stopped" notice', (tester) async {
      await prepareComposeBoxWithNavigation(tester);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      (await ZulipApp.navigator).pop();
      await tester.pump(Duration.zero);
      checkTypingRequest(TypingOp.stop, narrow);
    });

    testWidgets('for content input, unfocusing sends a "typing stopped" notice '
                'and refocusing sends a "typing started" notice', (tester) async {
      const narrow = ChannelNarrow(123);
      final destinationNarrow = TopicNarrow(narrow.streamId, 'test topic');
      await prepareComposeBox(
        tester, narrow: narrow, topic: destinationNarrow.topic);

      await checkStartTyping(tester, destinationNarrow);

      connection.prepare(json: {});
      FocusManager.instance.primaryFocus!.unfocus();
      await tester.pump(Duration.zero);
      checkTypingRequest(TypingOp.stop, destinationNarrow);

      connection.prepare(json: {});
      await tester.tap(contentInputFinder);
      checkTypingRequest(TypingOp.start, destinationNarrow);

      // Ensures that a "typing stopped" notice is sent when the test ends.
      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, destinationNarrow);
    });

    testWidgets('selection change sends a "typing started" notice', (tester) async {
      final controllerKey = await prepareComposeBox(tester, narrow: narrow);
      final composeBoxController = controllerKey.currentState!;

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, narrow);

      connection.prepare(json: {});
      composeBoxController.contentController.selection =
        const TextSelection(baseOffset: 0, extentOffset: 2);
      checkTypingRequest(TypingOp.start, narrow);

      // Ensures that a "typing stopped" notice is sent when the test ends.
      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, narrow);
    });

    testWidgets('unfocusing app sends a "typing stopped" notice', (tester) async {
      await prepareComposeBox(tester, narrow: narrow);

      await checkStartTyping(tester, narrow);

      connection.prepare(json: {});
      // While this state lives on [ServicesBinding], testWidgets resets it
      // for us when the test ends so we don't have to:
      //   https://github.com/flutter/flutter/blob/c78c166e3ecf963ca29ed503e710fd3c71eda5c9/packages/flutter_test/lib/src/binding.dart#L1189
      // On iOS and Android, a transition to [hidden] is synthesized before
      // transitioning into [paused].
      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.hidden);
      await tester.pump(Duration.zero);
      checkTypingRequest(TypingOp.stop, narrow);

      WidgetsBinding.instance.handleAppLifecycleStateChanged(
        AppLifecycleState.paused);
      await tester.pump(Duration.zero);
      check(connection.lastRequest).isNull();
    });

    testWidgets('interacting with compose buttons sends a "typing started" notice', (tester) async {
      final controllerKey = await prepareComposeBox(tester, narrow: narrow);
      final composeBoxController = controllerKey.currentState!;

      testBinding.pickImageResult = XFile.fromData(
        // TODO test inference of MIME type when it's missing here
        mimeType: 'image/jpeg',
        utf8.encode('asdf'),
        name: 'image.jpg',
        length: 12345,
        path: '/private/var/mobile/Containers/Data/Application/foo/tmp/image.jpg',
      );

      connection.prepare(json: {});
      check(composeBoxController.contentController.textNormalized).isEmpty();
      await tester.tap(find.byIcon(Icons.camera_alt));
      // The content is unchanged because the user has not picked an image yet;
      // otherwise a placeholder text will be added, which triggers a "typing
      // started" notice.  A "typing started" notice is still sent because
      // interactions with the compose buttons also count as typing activities.
      check(composeBoxController.contentController.textNormalized).isEmpty();
      checkTypingRequest(TypingOp.start, narrow);

      connection.prepare(json:
        UploadFileResult(uri: '/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg').toJson());
      await tester.pump(Duration.zero);
      check(composeBoxController.contentController.textNormalized).isNotEmpty();
      check(connection.takeRequests()).single.isA<http.MultipartRequest>();

      // Ensures that a "typing stopped" notice is sent when the test ends.
      connection.prepare(json: {});
      await tester.pump(store.typingNotifier.typingStoppedWaitPeriod);
      checkTypingRequest(TypingOp.stop, narrow);
    });
  });

  group('message-send request response', () {
    Future<void> setupAndTapSend(WidgetTester tester, {
      required void Function(int messageId) prepareResponse,
    }) async {
      TypingNotifier.debugEnable = false;
      addTearDown(TypingNotifier.debugReset);

      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      await prepareComposeBox(tester, narrow: const TopicNarrow(123, 'some topic'));

      await tester.enterText(contentInputFinder, 'hello world');

      prepareResponse(456);
      await tester.tap(find.byTooltip(zulipLocalizations.composeBoxSendTooltip));
      await tester.pump(Duration.zero);

      check(connection.lastRequest).isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/messages')
        ..bodyFields.deepEquals({
            'type': 'stream',
            'to': '123',
            'topic': 'some topic',
            'content': 'hello world',
            'read_by_sender': 'true',
          });
    }

    testWidgets('success', (tester) async {
      await setupAndTapSend(tester, prepareResponse: (int messageId) {
        connection.prepare(json: SendMessageResult(id: messageId).toJson());
      });
      final errorDialogs = tester.widgetList(find.byType(AlertDialog));
      check(errorDialogs).isEmpty();
    });

    testWidgets('ZulipApiException', (tester) async {
      await setupAndTapSend(tester, prepareResponse: (message) {
        connection.prepare(
          httpStatus: 400,
          json: {
            'result': 'error',
            'code': 'BAD_REQUEST',
            'msg': 'You do not have permission to initiate direct message conversations.',
          });
      });
      final zulipLocalizations = GlobalLocalizations.zulipLocalizations;
      await tester.tap(find.byWidget(checkErrorDialog(tester,
        expectedTitle: zulipLocalizations.errorMessageNotSent,
        expectedMessage: zulipLocalizations.errorServerMessage(
          'You do not have permission to initiate direct message conversations.'),
      )));
    });
  });

  group('uploads', () {
    void checkAppearsLoading(WidgetTester tester, bool expected) {
      final sendButtonElement = tester.element(find.ancestor(
        of: find.byIcon(Icons.send),
        matching: find.byType(IconButton)));
      final sendButtonWidget = sendButtonElement.widget as IconButton;
      final colorScheme = Theme.of(sendButtonElement).colorScheme;
      final expectedForegroundColor = expected
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : colorScheme.onPrimary;
      check(sendButtonWidget.color).isNotNull().isSameColorAs(expectedForegroundColor);
    }

    group('attach from media library', () {
      testWidgets('success', (tester) async {
        TypingNotifier.debugEnable = false;
        addTearDown(TypingNotifier.debugReset);

        final controllerKey = await prepareComposeBox(tester,
          narrow: ChannelNarrow(eg.stream().streamId),
          topic: 'some topic', content: 'see image: ');
        final composeBoxController = controllerKey.currentState!;
        // (When we check that the send button looks disabled, it should be because
        // the file is uploading, not a pre-existing reason.)
        checkAppearsLoading(tester, false);

        testBinding.pickFilesResult = FilePickerResult([PlatformFile(
          readStream: Stream.fromIterable(['asdf'.codeUnits]),
          // TODO test inference of MIME type from initial bytes, when
          //   it can't be inferred from path
          path: '/private/var/mobile/Containers/Data/Application/foo/tmp/image.jpg',
          name: 'image.jpg',
          size: 12345,
        )]);
        connection.prepare(delay: const Duration(seconds: 1), json:
          UploadFileResult(uri: '/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg').toJson());

        await tester.tap(find.byIcon(Icons.image));
        await tester.pump();
        final call = testBinding.takePickFilesCalls().single;
        check(call.allowMultiple).equals(true);
        check(call.type).equals(FileType.media);

        final errorDialogs = tester.widgetList(find.byType(AlertDialog));
        check(errorDialogs).isEmpty();

        await tester.pump(Duration.zero); // picked a file
        check(composeBoxController.contentController.text)
          .equals('see image: [Uploading image.jpg…]()\n\n');
        // (the request is checked more thoroughly in API tests)
        check(connection.lastRequest!).isA<http.MultipartRequest>()
          ..method.equals('POST')
          ..files.single.which((it) => it
            ..field.equals('file')
            ..length.equals(12345)
            ..filename.equals('image.jpg')
            ..contentType.asString.equals('image/jpeg')
            ..has<Future<List<int>>>((f) => f.finalize().toBytes(), 'contents')
              .completes((it) => it.deepEquals(['asdf'.codeUnits].expand((l) => l)))
          );
        checkAppearsLoading(tester, true);

        await tester.pump(const Duration(seconds: 1));
        check(composeBoxController.contentController.text)
          .equals('see image: [image.jpg](/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg)\n\n');
        checkAppearsLoading(tester, false);
      });

      // TODO test what happens when selecting/uploading fails
    });

    group('attach from camera', () {
      testWidgets('success', (tester) async {
        TypingNotifier.debugEnable = false;
        addTearDown(TypingNotifier.debugReset);

        final controllerKey = await prepareComposeBox(tester,
          narrow: ChannelNarrow(eg.stream().streamId),
          topic: 'some topic', content: 'see image: ');
        final composeBoxController = controllerKey.currentState!;
        // (When we check that the send button looks disabled, it should be because
        // the file is uploading, not a pre-existing reason.)
        checkAppearsLoading(tester, false);

        testBinding.pickImageResult = XFile.fromData(
          // TODO test inference of MIME type when it's missing here
          mimeType: 'image/jpeg',
          utf8.encode('asdf'),
          name: 'image.jpg',
          length: 12345,
          path: '/private/var/mobile/Containers/Data/Application/foo/tmp/image.jpg',
        );
        connection.prepare(delay: const Duration(seconds: 1), json:
          UploadFileResult(uri: '/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg').toJson());

        await tester.tap(find.byIcon(Icons.camera_alt));
        await tester.pump();
        final call = testBinding.takePickImageCalls().single;
        check(call.source).equals(ImageSource.camera);
        check(call.requestFullMetadata).equals(false);

        final errorDialogs = tester.widgetList(find.byType(AlertDialog));
        check(errorDialogs).isEmpty();

        await tester.pump(Duration.zero); // picked an image
        check(composeBoxController.contentController.text)
          .equals('see image: [Uploading image.jpg…]()\n\n');
        // (the request is checked more thoroughly in API tests)
        check(connection.lastRequest!).isA<http.MultipartRequest>()
          ..method.equals('POST')
          ..files.single.which((it) => it
            ..field.equals('file')
            ..length.equals(12345)
            ..filename.equals('image.jpg')
            ..contentType.asString.equals('image/jpeg')
            ..has<Future<List<int>>>((f) => f.finalize().toBytes(), 'contents')
              .completes((it) => it.deepEquals(['asdf'.codeUnits].expand((l) => l)))
          );
        checkAppearsLoading(tester, true);

        await tester.pump(const Duration(seconds: 1));
        check(composeBoxController.contentController.text)
          .equals('see image: [image.jpg](/user_uploads/1/4e/m2A3MSqFnWRLUf9SaPzQ0Up_/image.jpg)\n\n');
        checkAppearsLoading(tester, false);
      });

      // TODO test what happens when capturing/uploading fails
    });
  });

  group('compose box in DMs with deactivated users', () {
    Finder contentFieldFinder() => find.descendant(
      of: find.byType(ComposeBox),
      matching: find.byType(TextField));

    Finder attachButtonFinder(IconData icon) => find.descendant(
      of: find.byType(ComposeBox),
      matching: find.widgetWithIcon(IconButton, icon));

    void checkComposeBoxParts({required bool areShown}) {
      check(contentFieldFinder().evaluate().length).equals(areShown ? 1 : 0);
      check(attachButtonFinder(Icons.attach_file).evaluate().length).equals(areShown ? 1 : 0);
      check(attachButtonFinder(Icons.image).evaluate().length).equals(areShown ? 1 : 0);
      check(attachButtonFinder(Icons.camera_alt).evaluate().length).equals(areShown ? 1 : 0);
    }

    void checkBanner({required bool isShown}) {
      final bannerTextFinder = find.text(GlobalLocalizations.zulipLocalizations
        .errorBannerDeactivatedDmLabel);
      check(bannerTextFinder.evaluate().length).equals(isShown ? 1 : 0);
    }

    void checkComposeBox({required bool isShown}) {
      checkComposeBoxParts(areShown: isShown);
      checkBanner(isShown: !isShown);
    }

    Future<void> changeUserStatus(WidgetTester tester,
        {required User user, required bool isActive}) async {
      await store.handleEvent(RealmUserUpdateEvent(id: 1,
        userId: user.userId, isActive: isActive));
      await tester.pump();
    }

    DmNarrow dmNarrowWith(User otherUser) => DmNarrow.withUser(otherUser.userId,
      selfUserId: eg.selfUser.userId);

    DmNarrow groupDmNarrowWith(List<User> otherUsers) => DmNarrow.withOtherUsers(
      otherUsers.map((u) => u.userId), selfUserId: eg.selfUser.userId);

    group('1:1 DMs', () {
      testWidgets('compose box replaced with a banner', (tester) async {
        final deactivatedUser = eg.user(isActive: false);
        await prepareComposeBox(tester, narrow: dmNarrowWith(deactivatedUser),
          users: [deactivatedUser]);
        checkComposeBox(isShown: false);
      });

      testWidgets('active user becomes deactivated -> '
          'compose box is replaced with a banner', (tester) async {
        final activeUser = eg.user(isActive: true);
        await prepareComposeBox(tester, narrow: dmNarrowWith(activeUser),
          users: [activeUser]);
        checkComposeBox(isShown: true);

        await changeUserStatus(tester, user: activeUser, isActive: false);
        checkComposeBox(isShown: false);
      });

      testWidgets('deactivated user becomes active -> '
          'banner is replaced with the compose box', (tester) async {
        final deactivatedUser = eg.user(isActive: false);
        await prepareComposeBox(tester, narrow: dmNarrowWith(deactivatedUser),
          users: [deactivatedUser]);
        checkComposeBox(isShown: false);

        await changeUserStatus(tester, user: deactivatedUser, isActive: true);
        checkComposeBox(isShown: true);
      });
    });

    group('group DMs', () {
      testWidgets('compose box replaced with a banner', (tester) async {
        final deactivatedUsers = [eg.user(isActive: false), eg.user(isActive: false)];
        await prepareComposeBox(tester, narrow: groupDmNarrowWith(deactivatedUsers),
          users: deactivatedUsers);
        checkComposeBox(isShown: false);
      });

      testWidgets('at least one user becomes deactivated -> '
          'compose box is replaced with a banner', (tester) async {
        final activeUsers = [eg.user(isActive: true), eg.user(isActive: true)];
        await prepareComposeBox(tester, narrow: groupDmNarrowWith(activeUsers),
          users: activeUsers);
        checkComposeBox(isShown: true);

        await changeUserStatus(tester, user: activeUsers[0], isActive: false);
        checkComposeBox(isShown: false);
      });

      testWidgets('all deactivated users become active -> '
          'banner is replaced with the compose box', (tester) async {
        final deactivatedUsers = [eg.user(isActive: false), eg.user(isActive: false)];
        await prepareComposeBox(tester, narrow: groupDmNarrowWith(deactivatedUsers),
          users: deactivatedUsers);
        checkComposeBox(isShown: false);

        await changeUserStatus(tester, user: deactivatedUsers[0], isActive: true);
        checkComposeBox(isShown: false);

        await changeUserStatus(tester, user: deactivatedUsers[1], isActive: true);
        checkComposeBox(isShown: true);
      });
    });
  });
}
