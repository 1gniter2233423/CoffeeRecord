import 'package:flutter/foundation.dart';
import '../models/brew_record.dart';
import '../database/database_helper.dart';

class BrewProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  List<BrewRecord> _records = [];
  bool _isLoading = false;

  List<BrewRecord> get records => _records;
  bool get isLoading => _isLoading;

  /// 加载所有记录
  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    _records = await _db.getAllRecords();

    _isLoading = false;
    notifyListeners();
  }

  /// 添加记录
  Future<int> addRecord(BrewRecord record) async {
    final id = await _db.insertRecord(record);
    record.id = id;
    _records.insert(0, record);
    notifyListeners();
    return id;
  }

  /// 更新记录
  Future<void> updateRecord(BrewRecord record) async {
    await _db.updateRecord(record);
    final index = _records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      _records[index] = record;
      notifyListeners();
    }
  }

  /// 删除记录
  Future<void> deleteRecord(int id) async {
    await _db.deleteRecord(id);
    _records.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  /// 获取记录总数
  Future<int> getRecordCount() async {
    return await _db.getRecordCount();
  }
}
