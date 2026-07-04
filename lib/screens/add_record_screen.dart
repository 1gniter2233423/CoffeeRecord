import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/brew_record.dart';
import '../providers/brew_provider.dart';

class AddRecordScreen extends StatefulWidget {
  final BrewRecord? editRecord;

  const AddRecordScreen({super.key, this.editRecord});

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _coffeeNameCtrl = TextEditingController();
  final _originCtrl = TextEditingController();
  final _coffeeVarietyCtrl = TextEditingController();
  final _processingMethodCtrl = TextEditingController();
  final _customProcessingCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  final _waterCtrl = TextEditingController();
  final _waterTempCtrl = TextEditingController();
  final _grindSettingCtrl = TextEditingController();
  final _grinderCtrl = TextEditingController();
  final _dripperCtrl = TextEditingController();
  final _filterPaperCtrl = TextEditingController();
  final _brewTechniqueCtrl = TextEditingController();
  final _goodFlavorsCtrl = TextEditingController();
  final _badFlavorsCtrl = TextEditingController();
  final _improvementCtrl = TextEditingController();

  String? _roastLevel;
  String? _processingMethod;
  bool _isCustomProcessing = false;
  int _brewEndMin = 0;
  int _brewEndSec = 0;
  bool _useEndTime = false;
  int _rating = 3;
  DateTime _brewDate = DateTime.now();
  bool _isSaving = false;

  // 注水段数据 — 每个元素包含开始时间(min/sec) + 注水量
  final List<_PourStageData> _pourStages = [];

  // 自动计算的粉水比
  String _ratioDisplay = '1:--';

  bool get _isEditing => widget.editRecord != null;

  // 烘焙度选项
  final _roastLevels = ['极浅烘', '浅烘', '中烘', '深烘', '极深烘'];
  // 处理法选项
  final _processingMethods = [
    '日晒', '水洗', '蜜处理', '厌氧',
    '二氧化碳浸渍', '酒桶发酵', '其他处理法',
  ];

  @override
  void initState() {
    super.initState();
    _doseCtrl.addListener(_updateRatio);
    _waterCtrl.addListener(_updateRatio);
    if (_isEditing) {
      _populateForm(widget.editRecord!);
    }
    // 默认一段注水
    if (_pourStages.isEmpty) {
      _pourStages.add(_PourStageData(stageNumber: 1));
    }
  }

  void _updateRatio() {
    final dose = double.tryParse(_doseCtrl.text);
    final water = double.tryParse(_waterCtrl.text);
    if (dose != null && water != null && dose > 0 && water > 0) {
      setState(() {
        _ratioDisplay = '1:${(water / dose).toStringAsFixed(1)}';
      });
    } else {
      setState(() => _ratioDisplay = '1:--');
    }
  }

  void _populateForm(BrewRecord record) {
    _coffeeNameCtrl.text = record.coffeeName;
    _originCtrl.text = record.origin ?? '';
    _coffeeVarietyCtrl.text = record.coffeeVariety ?? '';
    _doseCtrl.text = record.doseG.toString();
    _waterCtrl.text = record.waterMl.toString();
    _waterTempCtrl.text = record.waterTemp?.toString() ?? '';
    _grindSettingCtrl.text = record.grindSetting ?? '';
    _grinderCtrl.text = record.grinder ?? '';
    _dripperCtrl.text = record.dripper ?? '';
    _filterPaperCtrl.text = record.filterPaper ?? '';
    _brewTechniqueCtrl.text = record.brewTechnique ?? '';
    _goodFlavorsCtrl.text = record.goodFlavors ?? '';
    _badFlavorsCtrl.text = record.badFlavors ?? '';
    _improvementCtrl.text = record.improvement ?? '';
    _roastLevel = record.roastLevel;
    // 处理法：预设值或自定义
    final pm = record.processingMethod;
    if (pm != null && _processingMethods.contains(pm)) {
      _processingMethod = pm;
      _isCustomProcessing = false;
    } else if (pm != null && pm.isNotEmpty) {
      _processingMethod = '其他处理法';
      _isCustomProcessing = true;
      _customProcessingCtrl.text = pm;
    }
    // 冲煮结束时间
    if (record.brewTimeSec != null && _pourStages.isEmpty) {
      _brewEndMin = record.brewTimeSec! ~/ 60;
      _brewEndSec = record.brewTimeSec! % 60;
      _useEndTime = true;
    }
    if (record.rating != null) _rating = record.rating!;
    _brewDate = record.brewDate;

    _pourStages.clear();
    final stages = record.brewStages;
    if (stages.isNotEmpty) {
      double cumulative = 0;
      for (final s in stages) {
        cumulative += s.waterAmount;
        _pourStages.add(_PourStageData(
          stageNumber: s.stageNumber,
          startMinCtrl: TextEditingController(text: s.startMin.toString()),
          startSecCtrl: TextEditingController(text: s.startSec.toString()),
          waterCtrl: TextEditingController(text: cumulative.toStringAsFixed(0)),
        ));
      }
    } else {
      _pourStages.add(_PourStageData(stageNumber: 1));
    }
  }

  @override
  void dispose() {
    _doseCtrl.removeListener(_updateRatio);
    _waterCtrl.removeListener(_updateRatio);
    _coffeeNameCtrl.dispose();
    _originCtrl.dispose();
    _coffeeVarietyCtrl.dispose();
    _processingMethodCtrl.dispose();
    _customProcessingCtrl.dispose();
    _doseCtrl.dispose();
    _waterCtrl.dispose();
    _waterTempCtrl.dispose();
    _grindSettingCtrl.dispose();
    _grinderCtrl.dispose();
    _dripperCtrl.dispose();
    _filterPaperCtrl.dispose();
    _brewTechniqueCtrl.dispose();
    _goodFlavorsCtrl.dispose();
    _badFlavorsCtrl.dispose();
    _improvementCtrl.dispose();
    for (final s in _pourStages) {
      s.startMinCtrl.dispose();
      s.startSecCtrl.dispose();
      s.waterCtrl.dispose();
    }
    super.dispose();
  }

  // ============ 注水段 ============

  void _addPourStage() {
    setState(() {
      _pourStages.add(_PourStageData(stageNumber: _pourStages.length + 1));
    });
  }

  void _removePourStage(int index) {
    if (_pourStages.length <= 1) return;
    setState(() {
      _pourStages[index].startMinCtrl.dispose();
      _pourStages[index].startSecCtrl.dispose();
      _pourStages[index].waterCtrl.dispose();
      _pourStages.removeAt(index);
      for (var i = 0; i < _pourStages.length; i++) {
        _pourStages[i].stageNumber = i + 1;
      }
    });
  }

  double _getPerStageAmount(int stageIndex) {
    final current = double.tryParse(_pourStages[stageIndex].waterCtrl.text) ?? 0;
    if (stageIndex == 0) return current;
    final prev = double.tryParse(_pourStages[stageIndex - 1].waterCtrl.text) ?? 0;
    return (current - prev).clamp(0, current);
  }

  /// 总注水量（用最后一段的累计值）
  double get _totalWaterMl {
    if (_pourStages.isEmpty) return 0;
    final last = _pourStages.lastWhere(
      (s) => s.waterCtrl.text.isNotEmpty,
      orElse: () => _pourStages.last,
    );
    return double.tryParse(last.waterCtrl.text) ?? 0;
  }

  String? get _pourStagesJson {
    if (_pourStages.every((s) => s.waterCtrl.text.isEmpty)) return null;
    final list = <Map<String, dynamic>>[];
    for (int i = 0; i < _pourStages.length; i++) {
      final s = _PourStageData.parse(_pourStages[i]);
      list.add(BrewStage(
        stageNumber: s.stageNumber,
        startMin: s.startMin,
        startSec: s.startSec,
        waterAmount: _getPerStageAmount(i),
      ).toMap());
    }
    return json.encode(list);
  }

  // ============ 日期 ============

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _brewDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _brewDate = DateTime(
        picked.year, picked.month, picked.day,
        _brewDate.hour, _brewDate.minute,
      ));
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_brewDate),
    );
    if (picked != null) {
      setState(() => _brewDate = DateTime(
        _brewDate.year, _brewDate.month, _brewDate.day,
        picked.hour, picked.minute,
      ));
    }
  }

  // ============ 保存 ============

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final useStages = _pourStages.any((s) => s.waterCtrl.text.isNotEmpty);
    final brewTimeSec = _useEndTime ? _brewEndMin * 60 + _brewEndSec : null;
    final waterMl = useStages && _waterCtrl.text.isEmpty
        ? _totalWaterMl
        : (double.tryParse(_waterCtrl.text) ?? _totalWaterMl);

    // 处理法：选中预设或自定义输入
    String? finalProcessing;
    if (_processingMethod == '其他处理法') {
      finalProcessing = _customProcessingCtrl.text.trim();
      if (finalProcessing.isEmpty) finalProcessing = null;
    } else if (_processingMethod != null) {
      finalProcessing = _processingMethod;
    }

    final record = BrewRecord(
      id: widget.editRecord?.id,
      coffeeName: _coffeeNameCtrl.text.trim(),
      origin: _originCtrl.text.trim().isEmpty ? null : _originCtrl.text.trim(),
      coffeeVariety: _coffeeVarietyCtrl.text.trim().isEmpty
          ? null : _coffeeVarietyCtrl.text.trim(),
      roastLevel: _roastLevel,
      processingMethod: finalProcessing,
      doseG: double.parse(_doseCtrl.text),
      waterMl: waterMl,
      waterTemp: _waterTempCtrl.text.isEmpty
          ? null : double.parse(_waterTempCtrl.text),
      grindSetting: _grindSettingCtrl.text.trim().isEmpty
          ? null : _grindSettingCtrl.text.trim(),
      grinder: _grinderCtrl.text.trim().isEmpty
          ? null : _grinderCtrl.text.trim(),
      dripper: _dripperCtrl.text.trim().isEmpty
          ? null : _dripperCtrl.text.trim(),
      filterPaper: _filterPaperCtrl.text.trim().isEmpty
          ? null : _filterPaperCtrl.text.trim(),
      brewTimeSec: brewTimeSec,
      brewTechnique: _brewTechniqueCtrl.text.trim().isEmpty
          ? null : _brewTechniqueCtrl.text.trim(),
      brewStagesJson: _pourStagesJson,
      rating: _rating,
      goodFlavors: _goodFlavorsCtrl.text.trim().isEmpty
          ? null : _goodFlavorsCtrl.text.trim(),
      badFlavors: _badFlavorsCtrl.text.trim().isEmpty
          ? null : _badFlavorsCtrl.text.trim(),
      improvement: _improvementCtrl.text.trim().isEmpty
          ? null : _improvementCtrl.text.trim(),
      brewDate: _brewDate,
    );

    try {
      final provider = context.read<BrewProvider>();
      if (_isEditing) {
        await provider.updateRecord(record);
      } else {
        await provider.addRecord(record);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? '记录已更新 ☕' : '记录已保存 ☕'),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('保存失败: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ============ UI ============

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? '编辑记录' : '记录冲煮';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('保存',
                    style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCoffeeSection(),
            const SizedBox(height: 24),
            _buildBrewParamsSection(),
            const SizedBox(height: 24),
            _buildTechniqueSection(),
            const SizedBox(height: 24),
            _buildTastingSection(),
            const SizedBox(height: 24),
            _buildDateTimeSection(),
            const SizedBox(height: 40),
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ---------- 咖啡豆 ----------

  Widget _buildCoffeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('咖啡豆信息'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _coffeeNameCtrl,
          decoration: const InputDecoration(
            labelText: '咖啡豆名称 *', hintText: '例如：埃塞俄比亚 果丁丁',
            border: OutlineInputBorder(),
          ),
          validator: (v) => v == null || v.trim().isEmpty ? '请输入咖啡豆名称' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _originCtrl,
          decoration: const InputDecoration(
            labelText: '产地', hintText: '例如：埃塞俄比亚',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _coffeeVarietyCtrl,
          decoration: const InputDecoration(
            labelText: '豆种', hintText: '例如：Typica、Geisha、SL28、Pacamara',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _roastLevel,
                decoration: const InputDecoration(
                  labelText: '烘焙度', border: OutlineInputBorder(),
                ),
                items: _roastLevels
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _roastLevel = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _processingMethod,
                decoration: const InputDecoration(
                  labelText: '处理法', border: OutlineInputBorder(),
                ),
                items: _processingMethods
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _processingMethod = v;
                    _isCustomProcessing = v == '其他处理法';
                    if (!_isCustomProcessing) _customProcessingCtrl.clear();
                  });
                },
              ),
            ),
          ],
        ),
        // 自定义处理法输入
        if (_isCustomProcessing)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextFormField(
              controller: _customProcessingCtrl,
              decoration: const InputDecoration(
                labelText: '请输入处理法名称',
                hintText: '例如：双重厌氧、特殊发酵、红酒处理...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
      ],
    );
  }

  // ---------- 冲煮参数 ----------

  Widget _buildBrewParamsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('冲煮参数'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextFormField(
              controller: _grinderCtrl,
              decoration: const InputDecoration(
                labelText: '磨豆机', hintText: '例如：C40',
                border: OutlineInputBorder(),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              controller: _grindSettingCtrl,
              decoration: const InputDecoration(
                labelText: '研磨度', hintText: '例如：22格',
                border: OutlineInputBorder(),
              ),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextFormField(
              controller: _dripperCtrl,
              decoration: const InputDecoration(
                labelText: '滤杯', hintText: '例如：V60',
                border: OutlineInputBorder(),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              controller: _filterPaperCtrl,
              decoration: const InputDecoration(
                labelText: '滤纸', hintText: '例如：漂白',
                border: OutlineInputBorder(),
              ),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextFormField(
              controller: _doseCtrl,
              decoration: const InputDecoration(
                labelText: '粉量 (g) *', border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              validator: (v) => v == null || v.isEmpty ? '请输入粉量' : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              controller: _waterCtrl,
              decoration: const InputDecoration(
                labelText: '水量 (ml)', border: OutlineInputBorder(),
                suffixText: 'ml',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              controller: _waterTempCtrl,
              decoration: const InputDecoration(
                labelText: '水温 (℃)', border: OutlineInputBorder(),
                suffixText: '℃',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
            )),
          ],
        ),
        // 粉水比
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.brown[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.brown[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.brown[600], size: 18),
                const SizedBox(width: 8),
                Text('粉水比：$_ratioDisplay',
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500,
                    color: Colors.brown[700],
                  ),
                ),
                const Spacer(),
                if (_ratioDisplay != '1:--')
                  Text(_calculateStrength(),
                    style: TextStyle(fontSize: 13, color: Colors.brown[400]),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------- 冲煮手法 ----------

  Widget _buildTechniqueSection() {
    final showSummary = _pourStages.any((s) => s.waterCtrl.text.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('冲煮手法'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _brewTechniqueCtrl,
          decoration: const InputDecoration(
            labelText: '手法名称',
            hintText: '例如：三段式、一刀流、四六法',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // 注水段列表（只有注水卡，没有间隔卡）
        ...List.generate(_pourStages.length, (i) {
          return _buildPourCard(i);
        }),

        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _addPourStage,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('添加注水段'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.brown[600],
            side: BorderSide(color: Colors.brown[300]!),
          ),
        ),

        // 结束时间（总冲煮时间）
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('结束时间（总冲煮时间）：',
              style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _brewEndMin.toString(),
                decoration: const InputDecoration(
                  isDense: true, labelText: '分',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  _brewEndMin = int.tryParse(v) ?? 0;
                  _useEndTime = true;
                  setState(() {});
                },
              ),
            ),
            const Text(' : ', style: TextStyle(fontSize: 16)),
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _brewEndSec.toString().padLeft(2, '0'),
                decoration: const InputDecoration(
                  isDense: true, labelText: '秒',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  _brewEndSec = int.tryParse(v) ?? 0;
                  _useEndTime = true;
                  setState(() {});
                },
              ),
            ),
          ],
        ),

        if (showSummary) ...[
          const SizedBox(height: 16),
          // 汇总
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown[600]!, Colors.brown[700]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _totalItem(Icons.graphic_eq, _pourStages.length.toString(), '段'),
                _totalItem(Icons.water_drop, _totalWaterMl.toStringAsFixed(0), 'ml'),
                _totalItem(Icons.timer,
                  '${_brewEndMin.toString().padLeft(2, '0')}:${_brewEndSec.toString().padLeft(2, '0')}',
                  '总时间'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 注水卡片
  Widget _buildPourCard(int index) {
    final stage = _pourStages[index];
    final isFirst = index == 0;
    // 计算本段实际注水量
    double perStageMl = _getPerStageAmount(index);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      color: Colors.brown[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.brown[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: isFirst ? Colors.orange[700] : Colors.brown,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('${stage.stageNumber}',
                    style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14,
                    ),
                  )),
                ),
                const SizedBox(width: 8),
                Text(
                  isFirst ? '闷蒸' : '第${stage.stageNumber}段注水',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (!isFirst && perStageMl > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '（本段 ${perStageMl.toStringAsFixed(0)}ml）',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                const Spacer(),
                if (_pourStages.length > 1)
                  IconButton(
                    onPressed: () => _removePourStage(index),
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            // 开始时间 + 累计注水量
            Row(
              children: [
                Text(isFirst ? '开始 00:00' : '开始 ',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
                if (!isFirst) ...[
                  SizedBox(
                    width: 44,
                    child: TextFormField(
                      controller: stage.startMinCtrl,
                      decoration: const InputDecoration(
                        isDense: true, labelText: '分',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const Text(' : ', style: TextStyle(fontSize: 16)),
                  SizedBox(
                    width: 44,
                    child: TextFormField(
                      controller: stage.startSecCtrl,
                      decoration: const InputDecoration(
                        isDense: true, labelText: '秒',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: TextFormField(
                    controller: stage.waterCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: isFirst ? '闷蒸水量 (ml)' : '注到 (ml)',
                      hintText: isFirst ? '例：30' : '例：150',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
        )),
        Text(label, style: const TextStyle(
          fontSize: 12, color: Colors.white70,
        )),
      ],
    );
  }

  // ---------- 品鉴记录（爱心评分）----------

  Widget _buildTastingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('品鉴记录'),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('评分：'),
            const SizedBox(width: 8),
            ...List.generate(5, (i) {
              final filled = i < _rating;
              return GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    filled ? Icons.favorite : Icons.favorite_border,
                    color: filled ? Colors.red[400] : Colors.grey[300],
                    size: 30,
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _goodFlavorsCtrl,
          decoration: const InputDecoration(
            labelText: '好的风味',
            hintText: '花香、水果、巧克力、甜感...',
            border: OutlineInputBorder(), alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _badFlavorsCtrl,
          decoration: const InputDecoration(
            labelText: '不好的风味',
            hintText: '苦涩、涩感、杂味、过萃...',
            border: OutlineInputBorder(), alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _improvementCtrl,
          decoration: const InputDecoration(
            labelText: '改进方案',
            hintText: '下次可以调整研磨度、水温、注水方式...',
            border: OutlineInputBorder(), alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  // ---------- 时间 ----------

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('冲煮时间'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(DateFormat('yyyy/MM/dd').format(_brewDate)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectTime,
                icon: const Icon(Icons.access_time),
                label: Text(DateFormat('HH:mm').format(_brewDate)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.save),
        label: Text(_isSaving ? '保存中...' : '保存记录'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // ============ 工具 ============

  String _calculateStrength() {
    final dose = double.tryParse(_doseCtrl.text);
    final water = double.tryParse(_waterCtrl.text);
    if (dose == null || water == null || dose <= 0 || water <= 0) return '';
    final r = water / dose;
    if (r < 12) return '☕ 浓郁';
    if (r < 15) return '☕ 较浓';
    if (r < 17) return '☕ 适中';
    if (r < 19) return '☕ 偏淡';
    return '☕ 清淡';
  }

  Widget _sectionHeader(String text) {
    return Text(text, style: TextStyle(
      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown[700],
    ));
  }
}

// ============ 注水段数据 ============

class _PourStageData {
  int stageNumber;
  final TextEditingController startMinCtrl;
  final TextEditingController startSecCtrl;
  final TextEditingController waterCtrl;

  _PourStageData({
    required this.stageNumber,
    TextEditingController? startMinCtrl,
    TextEditingController? startSecCtrl,
    TextEditingController? waterCtrl,
  })  : startMinCtrl = startMinCtrl ?? TextEditingController(),
        startSecCtrl = startSecCtrl ?? TextEditingController(),
        waterCtrl = waterCtrl ?? TextEditingController();

  /// 解析为纯数据
  static _ParsedPourStage parse(_PourStageData d) => _ParsedPourStage(
        stageNumber: d.stageNumber,
        startMin: int.tryParse(d.startMinCtrl.text) ?? 0,
        startSec: int.tryParse(d.startSecCtrl.text) ?? 0,
        waterAmount: double.tryParse(d.waterCtrl.text) ?? 0,
      );
}

class _ParsedPourStage {
  final int stageNumber;
  final int startMin;
  final int startSec;
  final double waterAmount;

  _ParsedPourStage({
    required this.stageNumber,
    required this.startMin,
    required this.startSec,
    required this.waterAmount,
  });

  int get totalStartSec => startMin * 60 + startSec;
}
