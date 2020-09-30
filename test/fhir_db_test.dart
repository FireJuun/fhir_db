import 'package:fhir/r4.dart';
import 'package:fhir_db/resource_dao.dart';

void main() async {
  final ResourceDao resourceDao = ResourceDao();
  final resultResource = await resourceDao.save(
    Patient(
      resourceType: 'Patient',
      name: [HumanName(text: 'New Patient Name')],
      birthDate: Date(DateTime.now()),
    ),
  );
  final resultOrganization = await resourceDao.save(
    Organization(
      resourceType: 'Organization',
      name: 'HSWT LLC',
    ),
  );
  final resultObservation = await resourceDao.save(
    Observation(
        resourceType: 'Observation', code: CodeableConcept(text: 'text')),
  );
}
