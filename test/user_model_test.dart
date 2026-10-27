import 'package:flutter_test/flutter_test.dart';
import 'package:newblood4u_temp/models/user_model.dart';

void main() {
  const donor = UserModel(
    uid: 'sample-user-id',
    name: 'Sample Donor',
    email: 'donor@example.test',
    contact: '+237 600 000 000',
    bloodType: 'O+',
  );

  test('public donor record excludes private contact information', () {
    final publicRecord = donor.toDonorMap(area: 'Sample Town');

    expect(publicRecord.keys, containsAll(['uid', 'name', 'bloodType', 'area']));
    expect(publicRecord, isNot(contains('email')));
    expect(publicRecord, isNot(contains('contact')));
    expect(publicRecord['isAvailable'], isTrue);
  });

  test('private profile retains the account contact details', () {
    final privateRecord = donor.toPrivateMap();

    expect(privateRecord['email'], 'donor@example.test');
    expect(privateRecord['contact'], '+237 600 000 000');
    expect(privateRecord['isDonorAvailable'], isFalse);
  });
}
