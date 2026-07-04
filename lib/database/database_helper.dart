import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/brew_record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const _fileName = 'coffee_records.json';
  static List<BrewRecord>? _cache;
  static bool _dirty = false;

  Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_fileName';
  }

  /// 从文件读取所有记录
  Future<List<BrewRecord>> _readAll() async {
    if (_cache != null && !_dirty) return _cache!;
    try {
      final path = await _filePath;
      final file = File(path);
      if (!await file.exists()) {
        _cache = [];
        return _cache!;
      }
      final jsonStr = await file.readAsString();
      final List<dynamic> list = json.decode(jsonStr);
      _cache = list.map((e) => BrewRecord.fromMap(e as Map<String, dynamic>)).toList();
      _dirty = false;
      return _cache!;
    } catch (e) {
      debugPrint('Database read error: $e');
      _cache = [];
      return _cache!;
    }
  }

  /// 写入文件
  Future<void> _writeAll(List<BrewRecord> records) async {
    try {
      final path = await _filePath;
      final file = File(path);
      final jsonStr = json.encode(records.map((r) => r.toMap()).toList());
      await file.writeAsString(jsonStr);
      _cache = records;
      _dirty = false;
    } catch (e) {
      debugPrint('Database write error: $e');
    }
  }

  /// 插入一条记录
  Future<int> insertRecord(BrewRecord record) async {
    final records = await _readAll();
    final maxId = records.fold<int>(0, (max, r) => r.id != null && r.id! > max ? r.id! : max);
    record.id = maxId + 1;
    records.add(record);
    await _writeAll(records);
    return record.id!;
  }

  /// 获取所有记录，按冲煮日期倒序
  Future<List<BrewRecord>> getAllRecords() async {
    final records = await _readAll();
    records.sort((a, b) => b.brewDate.compareTo(a.brewDate));
    return records;
  }

  /// 获取单条记录
  Future<BrewRecord?> getRecord(int id) async {
    final records = await _readAll();
    try {
      return records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 更新记录
  Future<int> updateRecord(BrewRecord record) async {
    final records = await _readAll();
    final index = records.indexWhere((r) => r.id == record.id);
    if (index != -1) {
      records[index] = record;
      await _writeAll(records);
      return 1;
    }
    return 0;
  }

  /// 删除记录
  Future<int> deleteRecord(int id) async {
    final records = await _readAll();
    records.removeWhere((r) => r.id == id);
    await _writeAll(records);
    return 1;
  }

  /// 获取记录总数
  Future<int> getRecordCount() async {
    final records = await _readAll();
    return records.length;
  }
}
