import 'dart:io';
import 'dart:async';
import 'dart:convert';

abstract class ISerializable {
  Map serialize();
  void deSerialize(Map value);
}

class TypeStorage {

  static final TypeStorage _singleton = TypeStorage._internal();

  factory TypeStorage() {
    return _singleton;
  }

  TypeStorage._internal();

  String filePath;

  TypeStorage init(String storageFilepath){
    Timer.periodic(new Duration(seconds: 10), (timer) async{
      await this.save();
    });
    if (inited){
      return this;
    }else {
      filePath = storageFilepath;
      inited = true;
      return this;
    }
  }

  bool inited = false;

  Map coreStorage;
  String serialized;

  Future reload() async {
    File file = File(filePath);
    if (await file.exists()) {
      serialized = await file.readAsString();
      if (serialized.isEmpty){
        coreStorage = {};
      }else {
        coreStorage = jsonDecode(serialized);
      }
    }else{
      coreStorage = {};
    }
  }

  Future save() async {
    final current = jsonEncode(coreStorage);
    if (current!=serialized){
      File file = File(filePath);
      final writer = file.openWrite();
      serialized = current;
      writer.add(utf8.encode(serialized));
      await writer.close();
    }
  }

  void setValue<T>(String key, T value){
    coreStorage[key] = value;
  }

  T getValue<T>(String key){
    return coreStorage[key] as T;
  }

  void setObject(String key, ISerializable value){
    coreStorage[key] = value.serialize();
  }

  T getObject<T extends ISerializable>(String key, T Function() creator){
    final obj = creator();
    obj.deSerialize(coreStorage[key]);
    return obj;
  }

  void addToList<T extends ISerializable>(T value){
    final List<Map> list = coreStorage["LIST:" + T.toString()].cast<Map>() ?? <Map>[];
    list.add(value.serialize());
    coreStorage["LIST:" + T.toString()] = list;
  }

  T listPosition<T extends ISerializable>(int position, T Function() creator) {
    final List<Map> list = coreStorage["LIST:" + T.toString()].cast<Map>() ?? <Map>[];
    if (position >= list.length){
      return null;
    }
    final T obj = creator();
    obj.deSerialize(list[position]);
    return obj;
  }

  void removeAt<T extends ISerializable>(int position){
    final List<Map> list = coreStorage["LIST:" + T.toString()].cast<Map>() ?? <Map>[];
    if ( position >= list.length || position < 0) {
      throw IndexError(position, list);
    }
    list.removeAt(position);
    coreStorage[T] = list;
  }

  void updateAt<T extends ISerializable>(int position, T item){
    final List<Map> list = coreStorage["LIST:" + T.toString()].cast<Map>() ?? <Map>[];
    if ( position >= list.length || position < 0) {
      throw IndexError(position, list);
    }
    list[position] = item.serialize();
    coreStorage[T] = list;
  }

  List<T> findType<T extends ISerializable>(bool Function(T) where, int Function(T, T) sort, Function() creator){
    final List<Map> list = coreStorage["LIST:" + T.toString()].cast<Map>() ?? <Map>[];
    final List<T> typedList = <T>[];
    for (final map in list){
      final obj = creator();
      obj.deSerialize(map);
      typedList.add(obj);
    }
    typedList.sort(sort);
    return typedList.where(where).toList();
  }



}