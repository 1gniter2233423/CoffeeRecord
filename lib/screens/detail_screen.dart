import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/brew_record.dart';
import '../providers/brew_provider.dart';
import 'add_record_screen.dart';

class DetailScreen extends StatelessWidget {
  final BrewRecord record;

  const DetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(record.coffeeName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题卡片
            _HeaderCard(record: record),
            const SizedBox(height: 16),

            // 冲煮参数
            _SectionTitle(text: '冲煮参数'),
            const SizedBox(height: 8),
            _ParamGrid(record: record),
            const SizedBox(height: 12),

            // 设备信息
            if (record.grinder != null ||
                record.grindSetting != null ||
                record.dripper != null ||
                record.filterPaper != null) ...[
              _InfoRow(
                icon: Icons.settings,
                label: '磨豆机',
                value: record.grinder,
              ),
              _InfoRow(
                icon: Icons.tune,
                label: '研磨度',
                value: record.grindSetting,
              ),
              _InfoRow(
                icon: Icons.filter_alt_outlined,
                label: '滤杯',
                value: record.dripper,
              ),
              _InfoRow(
                icon: Icons.description_outlined,
                label: '滤纸',
                value: record.filterPaper,
              ),
              const SizedBox(height: 16),
            ],

            // 冲煮手法
            if (record.brewTechnique != null ||
                record.brewStages.isNotEmpty) ...[
              _SectionTitle(text: '冲煮手法'),
              const SizedBox(height: 8),
              if (record.brewTechnique != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    record.brewTechnique!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                ),
              if (record.brewStages.isNotEmpty)
                ...record.brewStages.map((stage) => _buildStageRow(stage)),
              const SizedBox(height: 16),
            ],

            // 品鉴记录
            if (record.rating != null ||
                record.goodFlavors != null ||
                record.badFlavors != null ||
                record.improvement != null) ...[
              _SectionTitle(text: '品鉴记录'),
              const SizedBox(height: 8),
              if (record.rating != null) ...[
                _RatingDisplay(rating: record.rating!),
                const SizedBox(height: 8),
              ],
              if (record.goodFlavors != null && record.goodFlavors!.isNotEmpty)
                _FlavorCard(
                  icon: Icons.thumb_up_alt,
                  color: Colors.green,
                  title: '好的风味',
                  content: record.goodFlavors!,
                ),
              if (record.badFlavors != null && record.badFlavors!.isNotEmpty)
                const SizedBox(height: 8),
              if (record.badFlavors != null && record.badFlavors!.isNotEmpty)
                _FlavorCard(
                  icon: Icons.thumb_down_alt,
                  color: Colors.red,
                  title: '不好的风味',
                  content: record.badFlavors!,
                ),
              if (record.improvement != null && record.improvement!.isNotEmpty)
                const SizedBox(height: 8),
              if (record.improvement != null && record.improvement!.isNotEmpty)
                _FlavorCard(
                  icon: Icons.lightbulb_outline,
                  color: Colors.amber[700]!,
                  title: '改进方案',
                  content: record.improvement!,
                ),
              const SizedBox(height: 16),
            ],

            // 基础信息
            _SectionTitle(text: '基本信息'),
            const SizedBox(height: 8),
            _InfoTile(
              icon: Icons.calendar_today,
              label: '冲煮日期',
              value: DateFormat('yyyy/MM/dd HH:mm').format(record.brewDate),
            ),
            if (record.coffeeVariety != null) ...[
              const SizedBox(height: 4),
              _InfoTile(
                icon: Icons.eco,
                label: '豆种',
                value: record.coffeeVariety!,
              ),
            ],
            if (record.processingMethod != null) ...[
              const SizedBox(height: 4),
              _InfoTile(
                icon: Icons.agriculture,
                label: '处理法',
                value: record.processingMethod!,
              ),
            ],
            if (record.waterTemp != null) ...[
              const SizedBox(height: 4),
              _InfoTile(
                icon: Icons.thermostat,
                label: '水温',
                value: '${record.waterTemp}℃',
              ),
            ],
            if (record.createdAt != record.brewDate) ...[
              const SizedBox(height: 4),
              _InfoTile(
                icon: Icons.history,
                label: '创建时间',
                value: DateFormat('yyyy/MM/dd HH:mm').format(record.createdAt),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStageRow(BrewStage stage) {
    // 计算累计水量
    final stages = record.brewStages;
    final index = stages.indexOf(stage);
    double cumulative = 0;
    for (int i = 0; i <= index; i++) {
      cumulative += stages[i].waterAmount;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.brown[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.brown[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(
                color: stage.stageNumber == 1 ? Colors.orange[700] : Colors.brown,
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('${stage.stageNumber}',
                style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13,
                ),
              )),
            ),
            const SizedBox(width: 10),
            Text(stage.stageNumber == 1 ? '闷蒸' : '第${stage.stageNumber}段',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            _stageDetail(Icons.timer_outlined, stage.startTimeDisplay),
            const SizedBox(width: 16),
            _stageDetail(Icons.water_drop, '${cumulative.toStringAsFixed(0)}ml'),
          ],
        ),
      ),
    );
  }

  Widget _stageDetail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
      ],
    );
  }

  void _navigateEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(editRecord: record),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定要删除「${record.coffeeName}」的记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BrewProvider>().deleteRecord(record.id!);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('记录已删除'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

// ============ 子组件 ============

class _HeaderCard extends StatelessWidget {
  final BrewRecord record;
  const _HeaderCard({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.coffee, size: 48, color: Colors.brown),
            const SizedBox(height: 12),
            Text(
              record.coffeeName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (record.origin != null)
                  Chip(
                    avatar: const Icon(Icons.public, size: 16),
                    label: Text(record.origin!),
                    visualDensity: VisualDensity.compact,
                  ),
                if (record.roastLevel != null)
                  Chip(
                    label: Text(record.roastLevel!),
                    visualDensity: VisualDensity.compact,
                  ),
                if (record.coffeeVariety != null)
                  Chip(
                    avatar: const Icon(Icons.eco, size: 16),
                    label: Text(record.coffeeVariety!),
                    visualDensity: VisualDensity.compact,
                  ),
                if (record.processingMethod != null)
                  Chip(
                    label: Text(record.processingMethod!),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '粉水比 ${record.ratioDisplay}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.brown[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParamGrid extends StatelessWidget {
  final BrewRecord record;
  const _ParamGrid({required this.record});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _ParamCard(
          icon: Icons.coffee_maker, label: '粉量', value: '${record.doseG}g',
        )),
        const SizedBox(width: 8),
        Expanded(child: _ParamCard(
          icon: Icons.water_drop, label: '水量', value: '${record.waterMl}ml',
        )),
        const SizedBox(width: 8),
        Expanded(child: _ParamCard(
          icon: Icons.swap_horiz, label: '粉水比', value: record.ratioDisplay,
        )),
        const SizedBox(width: 8),
        Expanded(child: _ParamCard(
          icon: Icons.timer, label: '时间', value: record.brewTimeDisplay,
        )),
      ],
    );
  }
}

class _ParamCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ParamCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.brown[100]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.brown[400], size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.brown[400]),
          const SizedBox(width: 6),
          Text('$label：', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Expanded(child: Text(value!, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}

class _FlavorCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String content;
  const _FlavorCard({
    required this.icon, required this.color,
    required this.title, required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 14,
              )),
            ],
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown[700]),
    );
  }
}

class _RatingDisplay extends StatelessWidget {
  final int rating;
  const _RatingDisplay({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.favorite : Icons.favorite_border,
          color: i < rating ? Colors.red[400] : Colors.grey[300],
          size: 30,
        );
      }),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text('$label：', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
