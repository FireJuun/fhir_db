import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../aes.dart';
// import '../salsa.dart';

class FhirDb {
  FhirDb._();
  static final FhirDb _db = FhirDb._();
  static FhirDb get instance => _db;

  Completer<Database> _dbOpenCompleter;

  Future<Database> get database {
    if (_dbOpenCompleter == null) {
      _dbOpenCompleter = Completer();
      _openDatabase();
    }
    return _dbOpenCompleter.future;
  }

  // String _getPw() => 'my password';

  Future _openDatabase() async {
    // var codec = getEncryptSembastCodecAES(password: _getPw());
    // var codec = getEncryptSembastCodecSalsa20(password: _getPw());
    // final dbPath = './test/fhir.db';
    // final database = await databaseFactoryIo.openDatabase(dbPath, codec: codec);
    // _dbOpenCompleter.complete(database);

    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocumentDir.path, 'r5fhir.db');
    final dbFactory = getDatabaseFactorySqflite(sqflite.databaseFactory);
    final database = await dbFactory.openDatabase(dbPath);
    _dbOpenCompleter.complete(database);
  }
}
