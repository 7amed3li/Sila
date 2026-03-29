import 'package:isar/isar.dart';
import 'package:sila_app/features/vefa/data/models/vefa_person_model.dart';

abstract class VefaLocalDataSource {
  Future<List<VefaPersonModel>> getVefaList();
  Future<int> addPerson(VefaPersonModel person);
  Future<void> updatePerson(VefaPersonModel person);
  Future<void> deletePerson(int id);
  Future<void> incrementGiftCount(int id);
}

class VefaLocalDataSourceImpl implements VefaLocalDataSource {
  VefaLocalDataSourceImpl(this.isar);
  final Isar isar;

  @override
  Future<List<VefaPersonModel>> getVefaList() async {
    return await isar.vefaPersonModels.where().limit(200).findAll();
  }

  @override
  Future<int> addPerson(VefaPersonModel person) async {
    return await isar.writeTxn(() async {
      return await isar.vefaPersonModels.put(person);
    });
  }

  @override
  Future<void> deletePerson(int id) async {
    await isar.writeTxn(() async {
      await isar.vefaPersonModels.delete(id);
    });
  }

  @override
  Future<void> updatePerson(VefaPersonModel person) async {
    await isar.writeTxn(() async {
      await isar.vefaPersonModels.put(person);
    });
  }

  @override
  Future<void> incrementGiftCount(int id) async {
    await isar.writeTxn(() async {
      final person = await isar.vefaPersonModels.get(id);
      if (person != null) {
        person.giftCount += 1;
        await isar.vefaPersonModels.put(person);
      }
    });
  }
}
