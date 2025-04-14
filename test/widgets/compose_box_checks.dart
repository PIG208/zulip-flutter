import 'package:checks/checks.dart';
import 'package:zulip/widgets/compose_box.dart';

extension ComposeControllerChecks<ErrorT> on Subject<ComposeController<ErrorT>> {
  Subject<String> get textNormalized => has((c) => c.textNormalized, 'textNormalized');
  Subject<List<ErrorT>> get validationErrors => has((c) => c.validationErrors, 'validationErrors');
}
