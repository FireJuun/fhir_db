import 'package:fhir/r4.dart';
import 'package:fhir_db/resource_dao.dart';

void main() async {
  final pw1 = 'new_password';
  final pw2 = 'newer_password';
  final ResourceDao resourceDao = ResourceDao();
  final resultPatient = await resourceDao.save(
    pw1,
    Patient(
      resourceType: 'Patient',
      name: [HumanName(text: 'New Patient Name')],
      birthDate: Date(DateTime.now()),
    ),
  );
  final resultOrganization = await resourceDao.save(
    pw1,
    Organization(
      resourceType: 'Organization',
      name: 'HSWT LLC',
    ),
  );
  final resultObservation = await resourceDao.save(
    pw1,
    Observation(
        resourceType: 'Observation', code: CodeableConcept(text: 'text')),
  );
  final patientList =
      await resourceDao.getAllSortedById(pw1, resourceType: 'Patient');
  await resourceDao.updatePw(pw1, pw2);
  for (var i in patientList) {
    print((i as Patient).toJson());
  }
}
