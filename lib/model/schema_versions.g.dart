// dart format width=80
import 'package:drift/internal/versioned_schema.dart' as i0;
import 'package:drift/drift.dart' as i1;
import 'package:drift/drift.dart'; // ignore_for_file: type=lint,unused_import

// GENERATED BY drift_dev, DO NOT MODIFY.
final class Schema2 extends i0.VersionedSchema {
  Schema2({required super.database}) : super(version: 2);
  @override
  late final List<i1.DatabaseSchemaEntity> entities = [
    accounts,
  ];
  late final Shape0 accounts = Shape0(
      source: i0.VersionedTable(
        entityName: 'accounts',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [
          'UNIQUE(realm_url, user_id)',
          'UNIQUE(realm_url, email)',
        ],
        columns: [
          _column_0,
          _column_1,
          _column_2,
          _column_3,
          _column_4,
          _column_5,
          _column_6,
          _column_7,
          _column_8,
        ],
        attachedDatabase: database,
      ),
      alias: null);
}

class Shape0 extends i0.VersionedTable {
  Shape0({required super.source, required super.alias}) : super.aliased();
  i1.GeneratedColumn<int> get id =>
      columnsByName['id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<String> get realmUrl =>
      columnsByName['realm_url']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<int> get userId =>
      columnsByName['user_id']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<String> get email =>
      columnsByName['email']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get apiKey =>
      columnsByName['api_key']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get zulipVersion =>
      columnsByName['zulip_version']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<String> get zulipMergeBase =>
      columnsByName['zulip_merge_base']! as i1.GeneratedColumn<String>;
  i1.GeneratedColumn<int> get zulipFeatureLevel =>
      columnsByName['zulip_feature_level']! as i1.GeneratedColumn<int>;
  i1.GeneratedColumn<String> get ackedPushToken =>
      columnsByName['acked_push_token']! as i1.GeneratedColumn<String>;
}

i1.GeneratedColumn<int> _column_0(String aliasedName) =>
    i1.GeneratedColumn<int>('id', aliasedName, false,
        hasAutoIncrement: true,
        type: i1.DriftSqlType.int,
        defaultConstraints:
            i1.GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
i1.GeneratedColumn<String> _column_1(String aliasedName) =>
    i1.GeneratedColumn<String>('realm_url', aliasedName, false,
        type: i1.DriftSqlType.string);
i1.GeneratedColumn<int> _column_2(String aliasedName) =>
    i1.GeneratedColumn<int>('user_id', aliasedName, false,
        type: i1.DriftSqlType.int);
i1.GeneratedColumn<String> _column_3(String aliasedName) =>
    i1.GeneratedColumn<String>('email', aliasedName, false,
        type: i1.DriftSqlType.string);
i1.GeneratedColumn<String> _column_4(String aliasedName) =>
    i1.GeneratedColumn<String>('api_key', aliasedName, false,
        type: i1.DriftSqlType.string);
i1.GeneratedColumn<String> _column_5(String aliasedName) =>
    i1.GeneratedColumn<String>('zulip_version', aliasedName, false,
        type: i1.DriftSqlType.string);
i1.GeneratedColumn<String> _column_6(String aliasedName) =>
    i1.GeneratedColumn<String>('zulip_merge_base', aliasedName, true,
        type: i1.DriftSqlType.string);
i1.GeneratedColumn<int> _column_7(String aliasedName) =>
    i1.GeneratedColumn<int>('zulip_feature_level', aliasedName, false,
        type: i1.DriftSqlType.int);
i1.GeneratedColumn<String> _column_8(String aliasedName) =>
    i1.GeneratedColumn<String>('acked_push_token', aliasedName, true,
        type: i1.DriftSqlType.string);

final class Schema3 extends i0.VersionedSchema {
  Schema3({required super.database}) : super(version: 3);
  @override
  late final List<i1.DatabaseSchemaEntity> entities = [
    accounts,
    globalSettings,
  ];
  late final Shape0 accounts = Shape0(
      source: i0.VersionedTable(
        entityName: 'accounts',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [
          'UNIQUE(realm_url, user_id)',
          'UNIQUE(realm_url, email)',
        ],
        columns: [
          _column_0,
          _column_1,
          _column_2,
          _column_3,
          _column_4,
          _column_5,
          _column_6,
          _column_7,
          _column_8,
        ],
        attachedDatabase: database,
      ),
      alias: null);
  late final Shape1 globalSettings = Shape1(
      source: i0.VersionedTable(
        entityName: 'global_settings',
        withoutRowId: false,
        isStrict: false,
        tableConstraints: [],
        columns: [
          _column_9,
        ],
        attachedDatabase: database,
      ),
      alias: null);
}

class Shape1 extends i0.VersionedTable {
  Shape1({required super.source, required super.alias}) : super.aliased();
  i1.GeneratedColumn<String> get themeSetting =>
      columnsByName['theme_setting']! as i1.GeneratedColumn<String>;
}

i1.GeneratedColumn<String> _column_9(String aliasedName) =>
    i1.GeneratedColumn<String>('theme_setting', aliasedName, false,
        type: i1.DriftSqlType.string,
        defaultValue: const CustomExpression('\'unset\''));
i0.MigrationStepWithVersion migrationSteps({
  required Future<void> Function(i1.Migrator m, Schema2 schema) from1To2,
  required Future<void> Function(i1.Migrator m, Schema3 schema) from2To3,
}) {
  return (currentVersion, database) async {
    switch (currentVersion) {
      case 1:
        final schema = Schema2(database: database);
        final migrator = i1.Migrator(database, schema);
        await from1To2(migrator, schema);
        return 2;
      case 2:
        final schema = Schema3(database: database);
        final migrator = i1.Migrator(database, schema);
        await from2To3(migrator, schema);
        return 3;
      default:
        throw ArgumentError.value('Unknown migration from $currentVersion');
    }
  };
}

i1.OnUpgrade stepByStep({
  required Future<void> Function(i1.Migrator m, Schema2 schema) from1To2,
  required Future<void> Function(i1.Migrator m, Schema3 schema) from2To3,
}) =>
    i0.VersionedSchema.stepByStepHelper(
        step: migrationSteps(
      from1To2: from1To2,
      from2To3: from2To3,
    ));
