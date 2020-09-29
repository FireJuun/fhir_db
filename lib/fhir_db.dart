import 'dart:async';

import 'package:fhir_db/encryption.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class FhirDb {
  FhirDb._();
  static final FhirDb _db = FhirDb._();
  static FhirDb get instance => _db;
  List<String> resourceTypes = [];

  void addResourceType(String resourceType) {
    if (!resourceTypes.contains(resourceType)) {
      resourceTypes.add(resourceType);
    }
  }

  void removeResourceTypes(List<String> typesToDelete) =>
      resourceTypes.removeWhere((type) => typesToDelete.contains(type));

  List<String> getResourceTypes() => resourceTypes;

  Completer<Database> _dbOpenCompleter;

  Future<Database> get database async {
    if (_dbOpenCompleter == null) {
      _dbOpenCompleter = Completer();
      _openDatabase();
    }
    return _dbOpenCompleter.future;
  }

  Future _openDatabase() async {
    var codec = getEncryptSembastCodec(password: 'my password');
    final dbPath = './test/fhir.db';
    final database = await databaseFactoryIo.openDatabase(dbPath, codec: codec);
    _dbOpenCompleter.complete(database);
  }
}
