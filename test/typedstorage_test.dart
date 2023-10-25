import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:typedstorage/src/storage.dart';
import 'package:coidentity/coidentity.dart';

class MyISharePreferences extends ISharePreferences {
  @override
  String? getString(String key) {
    return null;
  }

  @override
  void setString(String key, String? value) {}
}

class Process implements ICryptable {
  late CoreIdentity identity;
  Future init() async {
    identity = CoreIdentity();
    identity.setup(EncryptMethod.SECP256K1, MyISharePreferences());
  }

  static final Uint8List secret = Uint8List.fromList(
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 2]);
  static final Uint8List iv = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
  @override
  Future<Uint8List> process(Uint8List value) async {
    return await identity.processFile(value, secret, iv);
  }
}

class AType implements ISerializable {
  String? name;
  int? age;

  @override
  void deSerialize(Map value) {
    name = value['name'];
    age = value['age'];
  }

  @override
  Map serialize() {
    return {'name': name, 'age': age};
  }

  @override
  String toString() {
    return jsonEncode(this.serialize());
  }
}

void main() {
  test('test storage', () async {
    String filePath =
        "/Users/alex/Projects/workspace/typedstorage/test/mydb.json";

    if (await File(filePath).exists()) {
      File(filePath).deleteSync();
    }

    final encProcess = new Process();
    await encProcess.init();
    final store = TypeStorage().init(filePath, cryptor: encProcess);
    await store.reload();

    store.setValue<String>('testKey1', "哈哈哈");
    store.setValue<int>('testKey2', 123123);
    print(store.getValue<String>('testKey1'));
    AType person = AType();
    person.name = "Alex";
    person.age = 18;
    store.setObject('Person', person);

    await store.save();

    final p = store.getObject('Person', () => AType());
    print(p);

    final names = [
      'Bob',
      'Alice',
      'John',
      'Celina',
      'Eda',
      'Meachle',
      'Alex',
      'Bill'
    ];
    for (final name in names) {
      final ps = AType();
      ps.name = name;
      ps.age = 0;
      store.addToList<AType>(ps);
    }

    for (final pp in store.findType<AType>(
        where: (item) => item.name?.startsWith("A") == true,
        sort: (a, b) => (a.name?.length ?? 0).compareTo((b.name?.length ?? 0)),
        creator: () => AType())) {
      print(pp);
    }

    await store.save();

    String namedKey = 'student';

    store.createNamedList(namedKey, () => AType());

    for (final name in names) {
      final ps = AType();
      ps.name = name;
      ps.age = 0;
      store.namedListAppend<AType>(namedKey, ps);
    }

    final first = store.namedListFirst<AType>(namedKey);
    expect(first?.name, names[0]);

    final ls = store.namedListQuery<AType>(namedKey,
        where: (item) => item.name?.startsWith('A') == true,
        sort: (a, b) => (a.age ?? 0).compareTo((b.age ?? 0)));
    print('$ls');
  });
}
