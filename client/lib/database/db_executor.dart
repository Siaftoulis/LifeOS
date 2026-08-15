import 'package:drift/drift.dart';

import 'db_executor_web.dart'
    if (dart.library.io) 'db_executor_io.dart';

export 'db_executor_web.dart'
    if (dart.library.io) 'db_executor_io.dart';
