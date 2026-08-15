import 'dart:io';

File syncQueueFile() => File('${Directory.systemTemp.path}/sync_queue.json');
