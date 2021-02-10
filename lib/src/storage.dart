import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

abstract class ISerializable {
  Map serialize();
  void deSerialize(Map value);
}

abstract class ICryptable {
  Future<Uint8List> process(Uint8List value);
}

class TypeStorage {

  static final TypeStorage _singleton = TypeStorage._internal();

  factory TypeStorage() {
    return _singleton;
  }

  TypeStorage._internal();

  String filePath;

  ICryptable cryptor;

  TypeStorage init(String storageFilepath, {ICryptable cryptor}){
    this.cryptor = cryptor;
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
      final String savedStr = await file.readAsString();
      if (savedStr.startsWith('encrypted:')){
        final b64str = savedStr.substring(10);
        final rawBytes = await cryptor.process(base64Decode(b64str));
        serialized = utf8.decode(rawBytes.toList());
      }else{
        serialized=savedStr;
      }
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
      var storedStr;
      if (cryptor!=null){
        storedStr = "encrypted:" + base64Encode((await cryptor.process(Uint8List.fromList(utf8.encode(serialized)))).toList());
      }else{
        storedStr = serialized;
      }
      writer.add(utf8.encode(storedStr));
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

    final List list = coreStorage["LIST:" + T.toString()] ?? [];
    list.add(value.serialize());
    coreStorage["LIST:" + T.toString()] = list;
  }

  T listPosition<T extends ISerializable>(int position, T Function() creator) {
    final List list = coreStorage["LIST:" + T.toString()] ?? [];
    if (position >= list.length){
      return null;
    }
    final T obj = creator();
    obj.deSerialize(list[position] as Map);
    return obj;
  }

  void removeAt<T extends ISerializable>(int position){
    final List list = coreStorage["LIST:" + T.toString()] ?? [];
    if ( position >= list.length || position < 0) {
      throw IndexError(position, list);
    }
    list.removeAt(position);
    coreStorage[T] = list;
  }

  void updateAt<T extends ISerializable>(int position, T item){
    final List list = coreStorage["LIST:" + T.toString()] ?? [];
    if ( position >= list.length || position < 0) {
      throw IndexError(position, list);
    }
    list[position] = item.serialize();
    coreStorage[T] = list;
  }

  List<T> listAll<T extends ISerializable>(Function() creator) {
    final List list = coreStorage["LIST:" + T.toString()] ?? [];
    final List<T> typedList = <T>[];
    for (final map in list){
      final obj = creator();
      obj.deSerialize(map as Map);
      typedList.add(obj);
    }
    return typedList;
  }

  List<T> findType<T extends ISerializable>({@required bool Function(T) where, int Function(T, T) sort, Function() creator}){
    final List list = coreStorage["LIST:" + T.toString()] ?? [];
    final List<T> typedList = <T>[];
    for (final map in list){
      final obj = creator();
      obj.deSerialize(map as Map);
      typedList.add(obj);
    }
    typedList.sort(sort);
    return typedList.where(where).toList();
  }

  T listFirst<T extends ISerializable>(Function() creator){
    final List list = coreStorage["LIST:" + T.toString()] ?? [];
    if (list.length > 0){
      final obj = creator();
      obj.deSerialize(list[0] as Map);
      return obj;
    }
    return null;
  }

}