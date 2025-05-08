import '../core.dart';

/// https://zulip.com/api/create-saved-snippet
Future<void> createSavedSnippet(ApiConnection connection, {
  required String title,
  required String content,
}) {
  return connection.post('createSavedSnippet', (_) {}, 'saved_snippets', {
    'title': RawParameter(title),
    'content': RawParameter(content),
  });
}

/// https://zulip.com/api/edit-saved-snippet
Future<void> editSavedSnippet(ApiConnection connection, {
  required int savedSnippetId,
  required String? title,
  required String? content,
}) {
  return connection.patch('editSavedSnippet', (_) {}, 'saved_snippets/$savedSnippetId', {
    if (title != null) 'title': RawParameter(title),
    if (content != null) 'content': RawParameter(content),
  });
}
