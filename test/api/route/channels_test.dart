import 'package:checks/checks.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:zulip/api/model/model.dart';
import 'package:zulip/api/route/channels.dart';

import '../../stdlib_checks.dart';
import '../fake_api.dart';

void main() {
  test('smoke updateUserTopic', () {
    return FakeApiConnection.with_((connection) async {
      connection.prepare(json: {});
      await updateUserTopic(connection,
        streamId: 1, topic: 'topic',
        visibilityPolicy: UserTopicVisibilityPolicy.followed);
      check(connection.takeRequests()).single.isA<http.Request>()
        ..method.equals('POST')
        ..url.path.equals('/api/v1/user_topics')
        ..bodyFields.deepEquals({
          'stream_id': '1',
          'topic': 'topic',
          'visibility_policy': '3',
        });
    });
  });

  test('updateUserTopic only accepts valid visibility policy', () {
    return FakeApiConnection.with_((connection) async {
      check(() => updateUserTopic(connection,
        streamId: 1, topic: 'topic',
        visibilityPolicy: UserTopicVisibilityPolicy.unknown),
      ).throws<AssertionError>();
    });
  });
}
