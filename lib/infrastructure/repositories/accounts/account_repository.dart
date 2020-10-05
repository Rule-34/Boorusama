import 'package:boorusama/domain/accounts/account.dart';
import 'package:boorusama/domain/accounts/i_account_repository.dart';
import 'package:sqflite/sqflite.dart';

class AccountRepository implements IAccountRepository {
  final Future<Database> _db;

  AccountRepository(this._db);

  @override
  Future<void> add(Account account) async {
    final db = await _db;

    await db.insert("accounts", account.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<bool> exists(String username) {
    // TODO: implement exists
    throw UnimplementedError();
  }

  @override
  Future<List<Account>> getAll() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query("accounts");

    return List.generate(maps.length, (i) {
      return Account.create(maps[i]['username'], maps[i]['apiKey']);
    });
  }

  @override
  Future<void> remove(Account account) {
    // TODO: implement remove
    throw UnimplementedError();
  }
}
