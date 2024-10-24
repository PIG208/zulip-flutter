import 'package:json_annotation/json_annotation.dart';

import '../core.dart';
import '../model/model.dart';
part 'channels.g.dart';

/// https://zulip.com/api/get-stream-topics
Future<GetStreamTopicsResult> getStreamTopics(ApiConnection connection, {
  required int streamId,
}) {
  return connection.get('getStreamTopics', GetStreamTopicsResult.fromJson, 'users/me/$streamId/topics', {});
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetStreamTopicsResult {
  final List<GetStreamTopicsEntry> topics;

  GetStreamTopicsResult({
    required this.topics,
  });

  factory GetStreamTopicsResult.fromJson(Map<String, dynamic> json) =>
    _$GetStreamTopicsResultFromJson(json);

  Map<String, dynamic> toJson() => _$GetStreamTopicsResultToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class GetStreamTopicsEntry {
  final int maxId;
  final String name;

  GetStreamTopicsEntry({
    required this.maxId,
    required this.name,
  });

  factory GetStreamTopicsEntry.fromJson(Map<String, dynamic> json) => _$GetStreamTopicsEntryFromJson(json);

  Map<String, dynamic> toJson() => _$GetStreamTopicsEntryToJson(this);
}

/// https://zulip.com/api/update-user-topic
Future<void> updateUserTopic(ApiConnection connection, {
  required int streamId,
  required String topic,
  required UserTopicVisibilityPolicy visibilityPolicy,
}) {
  assert(visibilityPolicy != UserTopicVisibilityPolicy.unknown);
  return connection.post('updateUserTopic', (_) {}, 'user_topics', {
    'stream_id': streamId,
    'topic': RawParameter(topic),
    'visibility_policy': visibilityPolicy,
  });
}
