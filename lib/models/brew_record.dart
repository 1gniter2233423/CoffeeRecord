import 'dart:convert';

/// 单段注水记录
class BrewStage {
  int stageNumber; // 第几段
  int startMin; // 开始时间（分，从冲煮开始计时）
  int startSec; // 开始时间（秒）
  double waterAmount; // 本段注水量（ml）

  BrewStage({
    required this.stageNumber,
    this.startMin = 0,
    this.startSec = 0,
    required this.waterAmount,
  });

  /// 开始时间总秒数
  int get totalStartSec => startMin * 60 + startSec;

  /// 开始时间的格式化显示（mm:ss）
  String get startTimeDisplay =>
      '${startMin.toString().padLeft(2, '0')}:${startSec.toString().padLeft(2, '0')}';

  /// 与前一段的间隔秒数
  int intervalSec(BrewStage? previous) {
    if (previous == null) return 0;
    return totalStartSec - previous.totalStartSec;
  }

  /// 与前一段的间隔格式化显示
  String intervalDisplay(BrewStage? previous) {
    final sec = intervalSec(previous);
    if (sec == 0) return '0秒';
    if (sec < 60) return '$sec秒';
    return '${sec ~/ 60}分${sec % 60}秒';
  }

  Map<String, dynamic> toMap() => {
        'stageNumber': stageNumber,
        'startMin': startMin,
        'startSec': startSec,
        'waterAmount': waterAmount,
      };

  factory BrewStage.fromMap(Map<String, dynamic> map) => BrewStage(
        stageNumber: map['stageNumber'] as int,
        startMin: map['startMin'] as int? ?? 0,
        startSec: map['startSec'] as int? ?? 0,
        waterAmount: (map['waterAmount'] as num).toDouble(),
      );
}

class BrewRecord {
  int? id;
  String coffeeName;
  String? origin;
  String? coffeeVariety; // 豆种
  String? roastLevel; // 极浅烘 / 浅烘 / 中烘 / 深烘 / 极深烘
  String? processingMethod; // 日晒 / 水洗 / 蜜处理等
  double doseG; // 咖啡粉量（克）
  double waterMl; // 注水量（毫升）
  double? waterTemp; // 水温（℃）
  String? grindSetting; // 研磨度
  String? grinder; // 磨豆机
  String? dripper; // 滤杯
  String? filterPaper; // 滤纸
  int? brewTimeSec; // 总冲煮时间（秒）- 自动计算或手动
  String? brewTechnique; // 冲煮手法名称（如：三段式、一刀流）
  String? brewStagesJson; // 注水段 JSON
  int? rating; // 评分 1-5
  String? notes; // 风味笔记（旧字段，保留兼容）
  String? goodFlavors; // 好的风味
  String? badFlavors; // 不好的风味
  String? improvement; // 改进方案
  DateTime brewDate;
  DateTime createdAt;

  BrewRecord({
    this.id,
    required this.coffeeName,
    this.origin,
    this.coffeeVariety,
    this.roastLevel,
    this.processingMethod,
    required this.doseG,
    required this.waterMl,
    this.waterTemp,
    this.grindSetting,
    this.grinder,
    this.dripper,
    this.filterPaper,
    this.brewTimeSec,
    this.brewTechnique,
    this.brewStagesJson,
    this.rating,
    this.notes,
    this.goodFlavors,
    this.badFlavors,
    this.improvement,
    DateTime? brewDate,
    DateTime? createdAt,
  })  : brewDate = brewDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  // ============ 注水段解析 ============

  /// 解析注水段列表
  List<BrewStage> get brewStages {
    if (brewStagesJson == null || brewStagesJson!.isEmpty) return [];
    try {
      final List<dynamic> list = json.decode(brewStagesJson!);
      return list.map((e) => BrewStage.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 从注水段计算的总冲煮时间（秒）
  int get brewTimeFromStages {
    final stages = brewStages;
    if (stages.isEmpty) return brewTimeSec ?? 0;
    final last = stages.last;
    return last.totalStartSec;
  }

  /// 从注水段计算的注水总量
  double get totalWaterFromStages {
    final stages = brewStages;
    if (stages.isEmpty) return waterMl;
    return stages.fold<double>(0, (sum, s) => sum + s.waterAmount);
  }

  // ============ 计算属性 ============

  /// 粉水比
  double get ratio => waterMl / doseG;

  /// 粉水比的格式化显示
  String get ratioDisplay => '1:${ratio.toStringAsFixed(1)}';

  /// 冲煮时间格式化显示 (mm:ss)，使用 brewTimeSec（结束时间）
  String get brewTimeDisplay {
    final secs = brewTimeSec ?? 0;
    if (secs == 0) return '--';
    final minutes = secs ~/ 60;
    final seconds = secs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ============ 序列化 ============

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'coffeeName': coffeeName,
      'origin': origin,
      'coffeeVariety': coffeeVariety,
      'roastLevel': roastLevel,
      'processingMethod': processingMethod,
      'doseG': doseG,
      'waterMl': waterMl,
      'waterTemp': waterTemp,
      'grindSetting': grindSetting,
      'grinder': grinder,
      'dripper': dripper,
      'filterPaper': filterPaper,
      'brewTimeSec': brewTimeSec,
      'brewTechnique': brewTechnique,
      'brewStagesJson': brewStagesJson,
      'rating': rating,
      'notes': notes,
      'goodFlavors': goodFlavors,
      'badFlavors': badFlavors,
      'improvement': improvement,
      'brewDate': brewDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BrewRecord.fromMap(Map<String, dynamic> map) {
    return BrewRecord(
      id: map['id'] as int?,
      coffeeName: map['coffeeName'] as String,
      origin: map['origin'] as String?,
      coffeeVariety: map['coffeeVariety'] as String?,
      roastLevel: map['roastLevel'] as String?,
      processingMethod: map['processingMethod'] as String?,
      doseG: (map['doseG'] as num).toDouble(),
      waterMl: (map['waterMl'] as num).toDouble(),
      waterTemp: (map['waterTemp'] as num?)?.toDouble(),
      grindSetting: map['grindSetting'] as String?,
      grinder: map['grinder'] as String?,
      dripper: map['dripper'] as String?,
      filterPaper: map['filterPaper'] as String?,
      brewTimeSec: map['brewTimeSec'] as int?,
      brewTechnique: map['brewTechnique'] as String?,
      brewStagesJson: map['brewStagesJson'] as String?,
      rating: map['rating'] as int?,
      notes: map['notes'] as String?,
      goodFlavors: map['goodFlavors'] as String?,
      badFlavors: map['badFlavors'] as String?,
      improvement: map['improvement'] as String?,
      brewDate: DateTime.parse(map['brewDate'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  BrewRecord copyWith({
    int? id,
    String? coffeeName,
    String? origin,
    String? coffeeVariety,
    String? roastLevel,
    String? processingMethod,
    double? doseG,
    double? waterMl,
    double? waterTemp,
    String? grindSetting,
    String? grinder,
    String? dripper,
    String? filterPaper,
    int? brewTimeSec,
    String? brewTechnique,
    String? brewStagesJson,
    int? rating,
    String? notes,
    String? goodFlavors,
    String? badFlavors,
    String? improvement,
    DateTime? brewDate,
    DateTime? createdAt,
  }) {
    return BrewRecord(
      id: id ?? this.id,
      coffeeName: coffeeName ?? this.coffeeName,
      origin: origin ?? this.origin,
      coffeeVariety: coffeeVariety ?? this.coffeeVariety,
      roastLevel: roastLevel ?? this.roastLevel,
      processingMethod: processingMethod ?? this.processingMethod,
      doseG: doseG ?? this.doseG,
      waterMl: waterMl ?? this.waterMl,
      waterTemp: waterTemp ?? this.waterTemp,
      grindSetting: grindSetting ?? this.grindSetting,
      grinder: grinder ?? this.grinder,
      dripper: dripper ?? this.dripper,
      filterPaper: filterPaper ?? this.filterPaper,
      brewTimeSec: brewTimeSec ?? this.brewTimeSec,
      brewTechnique: brewTechnique ?? this.brewTechnique,
      brewStagesJson: brewStagesJson ?? this.brewStagesJson,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      goodFlavors: goodFlavors ?? this.goodFlavors,
      badFlavors: badFlavors ?? this.badFlavors,
      improvement: improvement ?? this.improvement,
      brewDate: brewDate ?? this.brewDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
