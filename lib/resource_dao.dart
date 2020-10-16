import 'package:fhir/r4.dart';
import 'package:sembast/sembast.dart';

import 'fhir_db.dart';
part 'resource_dao_id_and_meta.dart';

class ResourceDao {
  ResourceDao();
  StoreRef<String, Map<String, dynamic>> _resourceStore;

  Future<Database> _db(String password) => FhirDb.instance.database(password);

  Future updatePw(String oldPw, String newPw) =>
      FhirDb.instance.updatePassword(oldPw, newPw);

  //allows a store per resourceType (one for Patient, one for Observation, etc.)
  void _setStoreType(String resourceType) =>
      _resourceStore = stringMapStoreFactory.store(resourceType);

  Future _addResourceType(String password, String resourceType) async {
    var typeStore = StoreRef<String, List<dynamic>>.main();
    var resourceTypes =
        (await typeStore.record('resourceTypes').get(await _db(password)))
            ?.toList();
    resourceTypes ??= <String>[];
    if (!resourceTypes.contains(resourceType)) {
      resourceTypes.add(resourceType);
    }
    await typeStore.record('resourceTypes').delete(await _db(password));
    await typeStore
        .record('resourceTypes')
        .put(await _db(password), resourceTypes);
  }

  void _removeResourceTypes(String password, List<String> types) async {
    var typeStore = StoreRef<String, List<dynamic>>.main();
    var resourceTypes =
        (await typeStore.record('resourceTypes').get(await _db(password)))
            ?.toList();
    resourceTypes ??= <String>[];
    types.forEach(resourceTypes.remove);
    await typeStore.record('resourceTypes').delete(await _db(password));
    await typeStore
        .record('resourceTypes')
        .put(await _db(password), resourceTypes);
  }

  //get list of resourceTypes stored in DB
  Future<List<String>> _getResourceTypes(String password) async {
    var typeStore = StoreRef<String, List<dynamic>>.main();
    var resourceTypes =
        (await typeStore.record('resourceTypes').get(await _db(password)))
            ?.toList();
    var returnList = <String>[];
    resourceTypes.forEach((s) => returnList.add(s as String));
    return returnList;
  }

  //checks if the resource already has an id, all resources downloaded should
  //have an id, and all resources already saved will have an id, so only brand
  //spanking new resources won't
  Future<Resource> save(String password, Resource resource) async {
    if (resource != null) {
      if (resource?.resourceType != null) {
        await _addResourceType(password, resource.resourceType);
        _setStoreType(resource.resourceType);
        return resource.id == null
            ? await _insert(password, resource)
            : await _update(password, resource);
      } else {
        throw const FormatException('ResourceType cannot be null');
      }
    } else {
      throw const FormatException('Resource to save cannot be null');
    }
  }

  //if no id, it will call _getIdAndMeta to provide the new (local, temporary
  // id) along with creating a metadata about the resource history, and then
  //returning that resource
  Future<Resource> _insert(String password, Resource resource) async {
    final _newResource = _newVersion(resource);
    await _resourceStore
        .record(_newResource.id.toString())
        .put(await _db(password), _newResource.toJson());
    return _newResource;
  }

  //looks to see if id is found for that type of resource, if it isn't (e.g.
  //when the resource is downloaded from the server), it will simply save that
  //resource into the db. If a version is found, it will save that old version
  //into the _history db store, then update the meta field in the current
  //resource, and then save that resource and return it
  Future<Resource> _update(String password, Resource resource) async {
    final finder = Finder(filter: Filter.byKey(resource.id.toString()));
    final oldResource = await _resourceStore
        .record(resource.id.toString())
        .get(await _db(password));
    if (oldResource == null) {
      await _resourceStore
          .record(resource.id.toString())
          .put(await _db(password), resource.toJson());
      return resource;
    } else {
      _setStoreType('_history');
      await _addResourceType(password, '_history');
      await _resourceStore.add(await _db(password), oldResource);
      _setStoreType(resource.resourceType);
      _addResourceType(password, resource.resourceType);
      final _newResource = _newVersion(resource);
      await _resourceStore.update(await _db(password), _newResource.toJson(),
          finder: finder);
      return _newResource;
    }
  }

  //pass in a resourceType or a resource, and db will delete all resources of
  //that type - Note: will NOT delete any _historical stores (must pass in
  //'_history' as the type for this to happen)
  Future deleteSingleType(String password,
      {String resourceType, Resource resource}) async {
    final type = resourceType ?? resource?.resourceType ?? '';
    if (type.isNotEmpty) {
      _setStoreType(resourceType);
      await _resourceStore.delete(await _db(password));
      _removeResourceTypes(password, [resourceType]);
    }
  }

  //Deletes all resources, including historical versions
  Future deleteAllResources(String password) async {
    final resourceTypes = await _getResourceTypes(password);
    for (var type in resourceTypes) {
      _setStoreType(type);
      await _resourceStore.delete(await _db(password));
    }
    _removeResourceTypes(password, resourceTypes);
  }

  //Delete specific resource
  Future delete(String password, Resource resource) async {
    _setStoreType(resource.resourceType);
    final finder = Finder(filter: Filter.equals('id', '${resource.id}'));
    await _resourceStore.delete(await _db(password), finder: finder);
  }

  //return all resources in the DB, including historical versions
  Future<List<Resource>> getAllResources(String password) async {
    final resourceTypes = await _getResourceTypes(password);
    final resourceList = <Resource>[];
    for (final resource in resourceTypes) {
      final partialList =
          await getAllSortedById(password, resourceType: resource);
      partialList.forEach(resourceList.add);
    }
    return resourceList;
  }

  //returns all resources of a specific type
  Future<List<Resource>> getAllSortedById(String password,
      {String resourceType, Resource resource}) async {
    final type = resourceType ?? resource?.resourceType ?? '';
    if (type.isNotEmpty) {
      _setStoreType(type);
      final finder = Finder(sortOrders: [SortOrder('id')]);
      return _search(password, finder);
    }
    return [];
  }

  //specific search function to search for a resource by id, passes this
  //finder to _search
  Future find(String password, {Resource resource, Finder oldFinder}) async {
    final finder =
        oldFinder ?? Finder(filter: Filter.equals('id', '${resource.id}'));
    _setStoreType(resource.resourceType);
    return _search(password, finder);
  }

  //more general search, can pass in other values other than id, but I haven't
  //done a lot of work or testing with this
  Future<List<Resource>> searchFor(
      String password, String resourceType, String field, String value) async {
    _setStoreType(resourceType);
    final finder = Finder(filter: Filter.equals(field, value));
    return await _search(password, finder);
  }

  //ultimate search function, must pass in finder
  Future<List<Resource>> _search(String password, Finder finder) async {
    final recordSnapshots =
        await _resourceStore.find(await _db(password), finder: finder);

    return recordSnapshots.map((snapshot) {
      final resource = Resource.fromJson(snapshot.value);
      return resource;
    }).toList();
  }
}
