import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class FhirDb {
  static final FhirDb _db = FhirDb._();
  static FhirDb get instance => _db;

  Completer<Database> _dbOpenCompleter;

  FhirDb._();

  Future<Database> get database async {
    if (_dbOpenCompleter == null) {
      _dbOpenCompleter = Completer();
      _openDatabase();
    }

    return _dbOpenCompleter.future;
  }

  Future _openDatabase() async {
    Directory current = Directory.current;
    final dbPath = join(current.toString(), 'fhir.db');
    var factory = getDatabaseFactorySqflite(sqflite.databaseFactory);
    final database = await factory.openDatabase(dbPath);

    _dbOpenCompleter.complete(database);
  }
}
