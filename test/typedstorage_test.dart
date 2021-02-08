import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import 'package:typedstorage/src/storage.dart';


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
    final store = TypeStorage().init('/Users/alex/Projects/workspace/typedstorage/test/mydb.json');
    await store.reload();

    store.setValue<String>('testKey1', "哈哈哈");
    store.setValue<int>('testKey2', 123123);
    print(store.getValue<String>('testKey'));
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
