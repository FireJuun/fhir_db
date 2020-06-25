import 'package:fhir/fhir_r4.dart';
import 'package:fhir_db/resource_dao.dart';

void main() async {
  ResourceDao resourceDao = ResourceDao('Observation');

  for (int i = 0; i < 10; i++) {
    Observation observation = Observation(
        id: Id(
            DateTime.now().toString().replaceAll(':', '').replaceAll(' ', '')),
        resourceType: 'Observation',
        code: CodeableConcept(text: 'newObservation'));

    await resourceDao.insert(observation);
  }
  var resources = await resourceDao.getAllSortedById();
  resources.forEach((resource) => print(resource.toJson()));
}
