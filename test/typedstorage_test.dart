import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:typedstorage/src/storage.dart';
import 'package:coidentity/coidentity.dart';


class Process implements ICryptable {
  CoreIdentity identity;
  Future init() async {
    identity = CoreIdentity();
    identity.setup(EncryptMethod.SECP256K1, null);
  }
  static final Uint8List SECRET = Uint8List.fromList([0,1,2,3,4,5,6,7,8,9,0,1,2,3,4,5,6,7,8,9,1,2]);
  static final Uint8List IV = Uint8List.fromList([1,2,3,4,5,6,7,8]);
  @override
  Future<Uint8List> process(Uint8List value) async{
    return await identity.processFile(value, SECRET, IV);
  }
}

class AType implements ISerializable{
  String name;
  int age;

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
  test('test storage', () async{
    String file_path = "/Users/alex/Projects/workspace/typedstorage/test/mydb.json";

    if (await File(file_path).exists()) {
      File(file_path).deleteSync();
    }

    final encProcess = new Process();
    await encProcess.init();
    final store = TypeStorage().init(file_path, cryptor: encProcess);
    await store.reload();

    store.setValue<String>('testKey1', "哈哈哈");
    store.setValue<int>('testKey2', 123123);
    print(store.getValue<String>('testKey1'));
    AType person = AType();
    person.name = "Alex";
    person.age=18;
    store.setObject('Person', person);

    await store.save();

    final p = store.getObject('Person', ()=>AType());
    print(p);

    final names = ['Bob', 'Alice', 'John', 'Celina', 'Eda', 'Meachle', 'Alex', 'Bill'];
    for (final name in names){
      final ps = AType();
      ps.name = name;
      ps.age=0;
      store.addToList<AType>(ps);
    }

    for (final pp in store.findType<AType>((item) => item.name.startsWith("A"), (a, b) => a.name.length.compareTo(b.name.length), () => AType())){
      print(pp);
    }

    await store.save();

  });
}
