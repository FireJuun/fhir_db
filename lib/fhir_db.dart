import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'aes.dart';
import 'secure_interface.dart';
// import 'salsa.dart';

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

  Future _openDatabase() async {
    final pw = SecureInterface.getPw();
    final appDocumentDir = await getApplicationDocumentsDirectory();
    final dbPath = join(appDocumentDir.path, 'fhir.db');
    final dbFactory = getDatabaseFactorySqflite(sqflite.databaseFactory);

    final codec =
        pw == null || pw == '' ? null : getEncryptSembastCodecAES(password: pw);
    // getEncryptSembastCodecSalsa20(password: pw);

    final database = codec == null
        ? await dbFactory.openDatabase(dbPath)
        : await dbFactory.openDatabase(dbPath, codec: codec);

    _dbOpenCompleter.complete(database);
  }
}
