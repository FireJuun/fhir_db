import 'dart:async';

import 'package:fhir_db/salsa.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class FhirDb {
  FhirDb._();
  static final FhirDb _db = FhirDb._();
  static FhirDb get instance => _db;

  Completer<Database> _dbOpenCompleter;

  Future<Database> database() async {
    if (_dbOpenCompleter == null) {
      _dbOpenCompleter = Completer();
      _openDatabase();
    }
    return _dbOpenCompleter.future;
  }

  Future _getPw() async => await 'my password';

  Future _openDatabase() async {
    var codec = getEncryptSembastCodec(password: await _getPw());
    final dbPath = './test/fhir.db';
    final database = await databaseFactoryIo.openDatabase(dbPath, codec: codec);
    _dbOpenCompleter.complete(database);
  }
}
