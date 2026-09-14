import 'dart:async';

import 'app/bootstrap.dart';

void main() {
  // bootstrap() is awaited inside the guarded zone, and it is the same zone
  // that calls WidgetsFlutterBinding.ensureInitialized() and runApp(). Those
  // three have to share a zone or Flutter's own error reporting ends up
  // detached from ours.
  //
  // Before this, main() called bootstrap() fire-and-forget: any failure during
  // startup - a missing Firebase config, a corrupt Hive box, a DI misgrant -
  // became an unhandled asynchronous error that nothing observed, and the app
  // simply showed nothing.
  runZonedGuarded<Future<void>>(
    bootstrap,
    reportBootstrapError,
  );
}
